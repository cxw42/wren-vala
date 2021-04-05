// trampoline.vala: Functions for class bindings
// Part of wren-vala
// By Christopher White <cxwembedded@gmail.com>
// SPDX-License-Identifier: MIT

[CCode(cheader_filename="wren-vala-merged.h")]
namespace Wren {

  /**
   * Trampolines for allocating Object subclasses.
   *
   * Requires that the vm userdata be a {@link GLib.Object} subclass that:
   * * has a tramp_ property returning an instance of this class; and
   * * implements {@link Wren.HasMethods}
   * */
  [CCode(cheader_filename="wren-vala-merged.h")]
  public class Tramp : Object {

    /**
     * Classes exposed to Wren
     *
     * Maps from {@link hash_key()} retval to index in {@link types}.
     */
    HashTable<string, uint> classes = new HashTable<string, uint>(str_hash, str_equal);

    /**
     * Types we can instantiate
     *
     * Indices map 1-1 to {@link allocators}.
     */
    public Array<GLib.Type> types = new Array<GLib.Type>();


    /**
     * Functions that instantiate those types.
     *
     * Indices map 1-1 to {@link types}.
     */
    public Array<ForeignMethodFn> allocators;

    /**
     * Methods exposed to Wren
     *
     * Maps from {@link hash_key()} retval to index in {@link methodImpls}.
     */
    HashTable<string, uint> methodIdxes = new HashTable<string, uint>(str_hash, str_equal);

    /**
     * Functions that implement methods
     */
    public Array<ForeignMethodFn> methodThunks;

    /**
     * Functions that implement methods
     */
    public Array<HasMethods.MethodImpl> methodImpls = new Array<HasMethods.MethodImpl>();

    // --- Helper functions ---------------------------------------

    /**
     * Get a Tramp instance from a VM.
     *
     * Requires the VM's userdata hold a GLib.Object instance with a
     * property called `tramp_`.
     */
    private static Tramp tramp_from_vm(VM vm)
    {
      var userdata = vm.GetUserData() as Object;
      assert(userdata != null);  // TODO better error handling
      Value self_value = Value(typeof(Tramp));
      userdata.get_property("tramp_", ref self_value);
      var self = self_value.get_object() as Tramp;
      assert(self != null);
      return self;
    }

    // --- Public interface ---------------------------------------

    /**
     * Make a hash key for a class or method.
     *
     * * You must specify neither isStatic nor signature for a class.
     * * You must specify both of those for a method.
     */
    public static string hash_key(string module, string className,
      bool isStatic = false, string? signature = null)
    {
      if(signature == null) {
        return @"$module!$className";
      } else {

        // $ = arbitrary character not valid in a Wren identifier
        var staticflag = isStatic ? "$" : "";

        return @"$module!$className.$staticflag$signature";
      }
    }

    /** Regex for foreign_decl_for_key */
    private static Regex fdfk_re = null;

    /**
     * Return a foreign-method declaration for a given hash key.
     *
     * This in effect reverses {@link hash_key}.
     */
    public static string foreign_decl_for_key(string key)
    {

      if(fdfk_re == null) {
        try {
          var ident = "(?:[A-Za-z_][A-Za-z_0-9]*)";
          fdfk_re = new Regex(
            "(?<module>%s)!(?<class>%s).(?<static>\\$?)(?<name>%s)(?<rest>.*)$".printf(
              ident, ident, ident));
        } catch(RegexError e) {
          debug("Could not create regex for Tramp.foreign_decl_for_key(): %s", e.message);
          assert(false);  // I can't go on
        }
      }

      MatchInfo matches;
      if(!fdfk_re.match(key, 0, out matches)) {
        return "INVALID_FORMAT!";  // an invalid function declaration
      }

      var declaration = new StringBuilder();
      declaration.append("foreign ");
      var staticflag = matches.fetch_named("static");
      if((!)staticflag != "") {
        declaration.append("static ");
      }

      declaration.append((!)matches.fetch_named("name"));

      var rest = (!)matches.fetch_named("rest");
      if(rest.data[0] == '=') { // setter
        declaration.append("=");
        rest = rest.substring(1);
      }

      // Parameters, if any: convert `_` to unique identifiers
      int paramnum = -1;
      if(rest.data[0] == '(') {
        declaration.append("(");
        var parms = rest.substring(1,rest.length-2).split(",");
        for(int i=0; i < parms.length; ++i) {
          if(i!=0) {
            declaration.append(",");
          }
          declaration.append_printf("p%d", ++paramnum);
        }
        declaration.append(")");
      }

      return declaration.str;
    } // foreign_decl_for_key

    /**
     * Return the allocator and finalizer functions for a type.
     */
    public ForeignClassMethods get_functions(string module, string className)
    {
      ForeignClassMethods retval = {};

      var key = hash_key(module, className);
      if(classes.contains(key)) {
        uint idx = classes[key];
        retval.allocate = allocators.data[idx];
        retval.finalize = deallocateObject;
        debug("Functions for %s @ %u: %p, %p", key, idx, &retval.allocate, &retval.finalize);
      }
      return retval;
    } // get_functions()

    /**
     * Get a method of a class.
     */
    public ForeignMethodFn get_method(string module, string className, bool isStatic,
      string signature)
    {
      ForeignMethodFn retval = null;

      var key = hash_key(module, className, isStatic, signature);
      assert(methodIdxes.contains(key));  // TODO better error handling

      uint idx = methodIdxes[key];
      retval = methodThunks.data[idx];
      debug("Function for %s @ %u: %p", key, idx, &retval);

      return retval;
    } // get_method()

    public static void foreach_method_of_type(GLib.Type type, GLib.HFunc<string,HasMethods.MethodImpl> callback)
    {
      var instance = Object.new(type);
      assert(instance != null);
      var has_methods = instance as HasMethods;
      if(has_methods != null) {
        debug("Getting methods of %s", type.to_string());
        var methods = new HashTable<string, HasMethods.MethodImpl>(str_hash, str_equal);
        has_methods.get_methods(ref methods);
        methods.foreach(callback);
      }
    }

    /**
     * Add a type.
     *
     * Idempotent.
     */
    public void add_type(string module, string className, GLib.Type type)
    {
      var key = hash_key(module, className);

      if(classes.contains(key)) {
        return;
      }

      types.append_val(type);
      classes[key] = types.length - 1;
      assert(types.length <= allocators.length);  // TODO better error handling
      debug("Class %s now at index %u", key, classes[key]);

      debug("Loading methods");
      foreach_method_of_type(type, (k,v) => {
        methodImpls.append_val(v);
        var idx = methodImpls.length - 1;
        methodIdxes[k] = idx;
      });
    }

    // --- Allocating and deallocating instances ------------------

    /**
     * Instantiate a foreign class
     *
     * @param vm    The Wren VM to use
     * @param index The index in {@link types} and {@link allocators} to use.
     */
    private static void instantiate(VM vm, uint index)
    {
      debug("instantiate: vm %p, index %u", vm, index);

      var self = tramp_from_vm(vm);
      assert(index < self.types.length);

      // Do the work!
      var type = self.types.data[index];
      var instance = Object.new(type);

      // ref() to counteract the automatic unref() at the end of this function
      instance.ref ();

      // Give the instance to Wren
      unowned Object **ppobject = (Object **)vm.SetSlotNewForeign(0, 0, sizeof(Object));
      *ppobject = instance;

      debug("index %u: %p", index, instance);
    }

    /** Free a GObject instance */
    private static void deallocateObject(void *data)
    {
      unowned Object **ppobject = (Object **)data;
      debug("deallocateObject %p\n", ppobject);
      if(ppobject != null) {
        unowned Object *obj = *ppobject;
        obj->unref();
      }
    }

    // This is incredibly tedious.  We hold 100 functions and pointers to them.
    private static void i0(VM vm) {
      instantiate(vm, 0);
    }
    private static void i1(VM vm) {
      instantiate(vm, 1);
    }
    private static void i2(VM vm) {
      instantiate(vm, 2);
    }
    private static void i3(VM vm) {
      instantiate(vm, 3);
    }
    private static void i4(VM vm) {
      instantiate(vm, 4);
    }
    private static void i5(VM vm) {
      instantiate(vm, 5);
    }
    private static void i6(VM vm) {
      instantiate(vm, 6);
    }
    private static void i7(VM vm) {
      instantiate(vm, 7);
    }
    private static void i8(VM vm) {
      instantiate(vm, 8);
    }
    private static void i9(VM vm) {
      instantiate(vm, 9);
    }
    private static void i10(VM vm) {
      instantiate(vm, 10);
    }
    private static void i11(VM vm) {
      instantiate(vm, 11);
    }
    private static void i12(VM vm) {
      instantiate(vm, 12);
    }
    private static void i13(VM vm) {
      instantiate(vm, 13);
    }
    private static void i14(VM vm) {
      instantiate(vm, 14);
    }
    private static void i15(VM vm) {
      instantiate(vm, 15);
    }
    private static void i16(VM vm) {
      instantiate(vm, 16);
    }
    private static void i17(VM vm) {
      instantiate(vm, 17);
    }
    private static void i18(VM vm) {
      instantiate(vm, 18);
    }
    private static void i19(VM vm) {
      instantiate(vm, 19);
    }
    private static void i20(VM vm) {
      instantiate(vm, 20);
    }
    private static void i21(VM vm) {
      instantiate(vm, 21);
    }
    private static void i22(VM vm) {
      instantiate(vm, 22);
    }
    private static void i23(VM vm) {
      instantiate(vm, 23);
    }
    private static void i24(VM vm) {
      instantiate(vm, 24);
    }
    private static void i25(VM vm) {
      instantiate(vm, 25);
    }
    private static void i26(VM vm) {
      instantiate(vm, 26);
    }
    private static void i27(VM vm) {
      instantiate(vm, 27);
    }
    private static void i28(VM vm) {
      instantiate(vm, 28);
    }
    private static void i29(VM vm) {
      instantiate(vm, 29);
    }
    private static void i30(VM vm) {
      instantiate(vm, 30);
    }
    private static void i31(VM vm) {
      instantiate(vm, 31);
    }
    private static void i32(VM vm) {
      instantiate(vm, 32);
    }
    private static void i33(VM vm) {
      instantiate(vm, 33);
    }
    private static void i34(VM vm) {
      instantiate(vm, 34);
    }
    private static void i35(VM vm) {
      instantiate(vm, 35);
    }
    private static void i36(VM vm) {
      instantiate(vm, 36);
    }
    private static void i37(VM vm) {
      instantiate(vm, 37);
    }
    private static void i38(VM vm) {
      instantiate(vm, 38);
    }
    private static void i39(VM vm) {
      instantiate(vm, 39);
    }
    private static void i40(VM vm) {
      instantiate(vm, 40);
    }
    private static void i41(VM vm) {
      instantiate(vm, 41);
    }
    private static void i42(VM vm) {
      instantiate(vm, 42);
    }
    private static void i43(VM vm) {
      instantiate(vm, 43);
    }
    private static void i44(VM vm) {
      instantiate(vm, 44);
    }
    private static void i45(VM vm) {
      instantiate(vm, 45);
    }
    private static void i46(VM vm) {
      instantiate(vm, 46);
    }
    private static void i47(VM vm) {
      instantiate(vm, 47);
    }
    private static void i48(VM vm) {
      instantiate(vm, 48);
    }
    private static void i49(VM vm) {
      instantiate(vm, 49);
    }
    private static void i50(VM vm) {
      instantiate(vm, 50);
    }
    private static void i51(VM vm) {
      instantiate(vm, 51);
    }
    private static void i52(VM vm) {
      instantiate(vm, 52);
    }
    private static void i53(VM vm) {
      instantiate(vm, 53);
    }
    private static void i54(VM vm) {
      instantiate(vm, 54);
    }
    private static void i55(VM vm) {
      instantiate(vm, 55);
    }
    private static void i56(VM vm) {
      instantiate(vm, 56);
    }
    private static void i57(VM vm) {
      instantiate(vm, 57);
    }
    private static void i58(VM vm) {
      instantiate(vm, 58);
    }
    private static void i59(VM vm) {
      instantiate(vm, 59);
    }
    private static void i60(VM vm) {
      instantiate(vm, 60);
    }
    private static void i61(VM vm) {
      instantiate(vm, 61);
    }
    private static void i62(VM vm) {
      instantiate(vm, 62);
    }
    private static void i63(VM vm) {
      instantiate(vm, 63);
    }
    private static void i64(VM vm) {
      instantiate(vm, 64);
    }
    private static void i65(VM vm) {
      instantiate(vm, 65);
    }
    private static void i66(VM vm) {
      instantiate(vm, 66);
    }
    private static void i67(VM vm) {
      instantiate(vm, 67);
    }
    private static void i68(VM vm) {
      instantiate(vm, 68);
    }
    private static void i69(VM vm) {
      instantiate(vm, 69);
    }
    private static void i70(VM vm) {
      instantiate(vm, 70);
    }
    private static void i71(VM vm) {
      instantiate(vm, 71);
    }
    private static void i72(VM vm) {
      instantiate(vm, 72);
    }
    private static void i73(VM vm) {
      instantiate(vm, 73);
    }
    private static void i74(VM vm) {
      instantiate(vm, 74);
    }
    private static void i75(VM vm) {
      instantiate(vm, 75);
    }
    private static void i76(VM vm) {
      instantiate(vm, 76);
    }
    private static void i77(VM vm) {
      instantiate(vm, 77);
    }
    private static void i78(VM vm) {
      instantiate(vm, 78);
    }
    private static void i79(VM vm) {
      instantiate(vm, 79);
    }
    private static void i80(VM vm) {
      instantiate(vm, 80);
    }
    private static void i81(VM vm) {
      instantiate(vm, 81);
    }
    private static void i82(VM vm) {
      instantiate(vm, 82);
    }
    private static void i83(VM vm) {
      instantiate(vm, 83);
    }
    private static void i84(VM vm) {
      instantiate(vm, 84);
    }
    private static void i85(VM vm) {
      instantiate(vm, 85);
    }
    private static void i86(VM vm) {
      instantiate(vm, 86);
    }
    private static void i87(VM vm) {
      instantiate(vm, 87);
    }
    private static void i88(VM vm) {
      instantiate(vm, 88);
    }
    private static void i89(VM vm) {
      instantiate(vm, 89);
    }
    private static void i90(VM vm) {
      instantiate(vm, 90);
    }
    private static void i91(VM vm) {
      instantiate(vm, 91);
    }
    private static void i92(VM vm) {
      instantiate(vm, 92);
    }
    private static void i93(VM vm) {
      instantiate(vm, 93);
    }
    private static void i94(VM vm) {
      instantiate(vm, 94);
    }
    private static void i95(VM vm) {
      instantiate(vm, 95);
    }
    private static void i96(VM vm) {
      instantiate(vm, 96);
    }
    private static void i97(VM vm) {
      instantiate(vm, 97);
    }
    private static void i98(VM vm) {
      instantiate(vm, 98);
    }
    private static void i99(VM vm) {
      instantiate(vm, 99);
    }

    // --- Calling methods ----------------------------------------

    /**
     * Call a method on a class instance
     *
     * @param vm    The Wren VM to use
     * @param index The index in {@link methodImpls} to use.
     */
    private static void call_method(VM vm, uint index)
    {
      debug("call_method: vm %p, index %u", vm, index);

      var self = tramp_from_vm(vm);
      assert(index < self.methodImpls.length);

      unowned Object **ppobject = (Object **)vm.GetSlotForeign(0);
      var vmv = vm.GetUserData() as Wren.VMV;
      self.methodImpls.data[index](*ppobject, vmv);
    }

    // Also tedious.  100 of these.  `cN` = call N
    private static void c0(VM vm) {
      call_method(vm, 0);
    }
    private static void c1(VM vm) {
      call_method(vm, 1);
    }
    private static void c2(VM vm) {
      call_method(vm, 2);
    }
    private static void c3(VM vm) {
      call_method(vm, 3);
    }
    private static void c4(VM vm) {
      call_method(vm, 4);
    }
    private static void c5(VM vm) {
      call_method(vm, 5);
    }
    private static void c6(VM vm) {
      call_method(vm, 6);
    }
    private static void c7(VM vm) {
      call_method(vm, 7);
    }
    private static void c8(VM vm) {
      call_method(vm, 8);
    }
    private static void c9(VM vm) {
      call_method(vm, 9);
    }
    private static void c10(VM vm) {
      call_method(vm, 10);
    }
    private static void c11(VM vm) {
      call_method(vm, 11);
    }
    private static void c12(VM vm) {
      call_method(vm, 12);
    }
    private static void c13(VM vm) {
      call_method(vm, 13);
    }
    private static void c14(VM vm) {
      call_method(vm, 14);
    }
    private static void c15(VM vm) {
      call_method(vm, 15);
    }
    private static void c16(VM vm) {
      call_method(vm, 16);
    }
    private static void c17(VM vm) {
      call_method(vm, 17);
    }
    private static void c18(VM vm) {
      call_method(vm, 18);
    }
    private static void c19(VM vm) {
      call_method(vm, 19);
    }
    private static void c20(VM vm) {
      call_method(vm, 20);
    }
    private static void c21(VM vm) {
      call_method(vm, 21);
    }
    private static void c22(VM vm) {
      call_method(vm, 22);
    }
    private static void c23(VM vm) {
      call_method(vm, 23);
    }
    private static void c24(VM vm) {
      call_method(vm, 24);
    }
    private static void c25(VM vm) {
      call_method(vm, 25);
    }
    private static void c26(VM vm) {
      call_method(vm, 26);
    }
    private static void c27(VM vm) {
      call_method(vm, 27);
    }
    private static void c28(VM vm) {
      call_method(vm, 28);
    }
    private static void c29(VM vm) {
      call_method(vm, 29);
    }
    private static void c30(VM vm) {
      call_method(vm, 30);
    }
    private static void c31(VM vm) {
      call_method(vm, 31);
    }
    private static void c32(VM vm) {
      call_method(vm, 32);
    }
    private static void c33(VM vm) {
      call_method(vm, 33);
    }
    private static void c34(VM vm) {
      call_method(vm, 34);
    }
    private static void c35(VM vm) {
      call_method(vm, 35);
    }
    private static void c36(VM vm) {
      call_method(vm, 36);
    }
    private static void c37(VM vm) {
      call_method(vm, 37);
    }
    private static void c38(VM vm) {
      call_method(vm, 38);
    }
    private static void c39(VM vm) {
      call_method(vm, 39);
    }
    private static void c40(VM vm) {
      call_method(vm, 40);
    }
    private static void c41(VM vm) {
      call_method(vm, 41);
    }
    private static void c42(VM vm) {
      call_method(vm, 42);
    }
    private static void c43(VM vm) {
      call_method(vm, 43);
    }
    private static void c44(VM vm) {
      call_method(vm, 44);
    }
    private static void c45(VM vm) {
      call_method(vm, 45);
    }
    private static void c46(VM vm) {
      call_method(vm, 46);
    }
    private static void c47(VM vm) {
      call_method(vm, 47);
    }
    private static void c48(VM vm) {
      call_method(vm, 48);
    }
    private static void c49(VM vm) {
      call_method(vm, 49);
    }
    private static void c50(VM vm) {
      call_method(vm, 50);
    }
    private static void c51(VM vm) {
      call_method(vm, 51);
    }
    private static void c52(VM vm) {
      call_method(vm, 52);
    }
    private static void c53(VM vm) {
      call_method(vm, 53);
    }
    private static void c54(VM vm) {
      call_method(vm, 54);
    }
    private static void c55(VM vm) {
      call_method(vm, 55);
    }
    private static void c56(VM vm) {
      call_method(vm, 56);
    }
    private static void c57(VM vm) {
      call_method(vm, 57);
    }
    private static void c58(VM vm) {
      call_method(vm, 58);
    }
    private static void c59(VM vm) {
      call_method(vm, 59);
    }
    private static void c60(VM vm) {
      call_method(vm, 60);
    }
    private static void c61(VM vm) {
      call_method(vm, 61);
    }
    private static void c62(VM vm) {
      call_method(vm, 62);
    }
    private static void c63(VM vm) {
      call_method(vm, 63);
    }
    private static void c64(VM vm) {
      call_method(vm, 64);
    }
    private static void c65(VM vm) {
      call_method(vm, 65);
    }
    private static void c66(VM vm) {
      call_method(vm, 66);
    }
    private static void c67(VM vm) {
      call_method(vm, 67);
    }
    private static void c68(VM vm) {
      call_method(vm, 68);
    }
    private static void c69(VM vm) {
      call_method(vm, 69);
    }
    private static void c70(VM vm) {
      call_method(vm, 70);
    }
    private static void c71(VM vm) {
      call_method(vm, 71);
    }
    private static void c72(VM vm) {
      call_method(vm, 72);
    }
    private static void c73(VM vm) {
      call_method(vm, 73);
    }
    private static void c74(VM vm) {
      call_method(vm, 74);
    }
    private static void c75(VM vm) {
      call_method(vm, 75);
    }
    private static void c76(VM vm) {
      call_method(vm, 76);
    }
    private static void c77(VM vm) {
      call_method(vm, 77);
    }
    private static void c78(VM vm) {
      call_method(vm, 78);
    }
    private static void c79(VM vm) {
      call_method(vm, 79);
    }
    private static void c80(VM vm) {
      call_method(vm, 80);
    }
    private static void c81(VM vm) {
      call_method(vm, 81);
    }
    private static void c82(VM vm) {
      call_method(vm, 82);
    }
    private static void c83(VM vm) {
      call_method(vm, 83);
    }
    private static void c84(VM vm) {
      call_method(vm, 84);
    }
    private static void c85(VM vm) {
      call_method(vm, 85);
    }
    private static void c86(VM vm) {
      call_method(vm, 86);
    }
    private static void c87(VM vm) {
      call_method(vm, 87);
    }
    private static void c88(VM vm) {
      call_method(vm, 88);
    }
    private static void c89(VM vm) {
      call_method(vm, 89);
    }
    private static void c90(VM vm) {
      call_method(vm, 90);
    }
    private static void c91(VM vm) {
      call_method(vm, 91);
    }
    private static void c92(VM vm) {
      call_method(vm, 92);
    }
    private static void c93(VM vm) {
      call_method(vm, 93);
    }
    private static void c94(VM vm) {
      call_method(vm, 94);
    }
    private static void c95(VM vm) {
      call_method(vm, 95);
    }
    private static void c96(VM vm) {
      call_method(vm, 96);
    }
    private static void c97(VM vm) {
      call_method(vm, 97);
    }
    private static void c98(VM vm) {
      call_method(vm, 98);
    }
    private static void c99(VM vm) {
      call_method(vm, 99);
    }

    // --- Constructor --------------------------------------------

    public Tramp() {

      allocators = new Array<ForeignMethodFn>();
      allocators.set_size(100);
      allocators.data[0] = i0;
      allocators.data[1] = i1;
      allocators.data[2] = i2;
      allocators.data[3] = i3;
      allocators.data[4] = i4;
      allocators.data[5] = i5;
      allocators.data[6] = i6;
      allocators.data[7] = i7;
      allocators.data[8] = i8;
      allocators.data[9] = i9;
      allocators.data[10] = i10;
      allocators.data[11] = i11;
      allocators.data[12] = i12;
      allocators.data[13] = i13;
      allocators.data[14] = i14;
      allocators.data[15] = i15;
      allocators.data[16] = i16;
      allocators.data[17] = i17;
      allocators.data[18] = i18;
      allocators.data[19] = i19;
      allocators.data[20] = i20;
      allocators.data[21] = i21;
      allocators.data[22] = i22;
      allocators.data[23] = i23;
      allocators.data[24] = i24;
      allocators.data[25] = i25;
      allocators.data[26] = i26;
      allocators.data[27] = i27;
      allocators.data[28] = i28;
      allocators.data[29] = i29;
      allocators.data[30] = i30;
      allocators.data[31] = i31;
      allocators.data[32] = i32;
      allocators.data[33] = i33;
      allocators.data[34] = i34;
      allocators.data[35] = i35;
      allocators.data[36] = i36;
      allocators.data[37] = i37;
      allocators.data[38] = i38;
      allocators.data[39] = i39;
      allocators.data[40] = i40;
      allocators.data[41] = i41;
      allocators.data[42] = i42;
      allocators.data[43] = i43;
      allocators.data[44] = i44;
      allocators.data[45] = i45;
      allocators.data[46] = i46;
      allocators.data[47] = i47;
      allocators.data[48] = i48;
      allocators.data[49] = i49;
      allocators.data[50] = i50;
      allocators.data[51] = i51;
      allocators.data[52] = i52;
      allocators.data[53] = i53;
      allocators.data[54] = i54;
      allocators.data[55] = i55;
      allocators.data[56] = i56;
      allocators.data[57] = i57;
      allocators.data[58] = i58;
      allocators.data[59] = i59;
      allocators.data[60] = i60;
      allocators.data[61] = i61;
      allocators.data[62] = i62;
      allocators.data[63] = i63;
      allocators.data[64] = i64;
      allocators.data[65] = i65;
      allocators.data[66] = i66;
      allocators.data[67] = i67;
      allocators.data[68] = i68;
      allocators.data[69] = i69;
      allocators.data[70] = i70;
      allocators.data[71] = i71;
      allocators.data[72] = i72;
      allocators.data[73] = i73;
      allocators.data[74] = i74;
      allocators.data[75] = i75;
      allocators.data[76] = i76;
      allocators.data[77] = i77;
      allocators.data[78] = i78;
      allocators.data[79] = i79;
      allocators.data[80] = i80;
      allocators.data[81] = i81;
      allocators.data[82] = i82;
      allocators.data[83] = i83;
      allocators.data[84] = i84;
      allocators.data[85] = i85;
      allocators.data[86] = i86;
      allocators.data[87] = i87;
      allocators.data[88] = i88;
      allocators.data[89] = i89;
      allocators.data[90] = i90;
      allocators.data[91] = i91;
      allocators.data[92] = i92;
      allocators.data[93] = i93;
      allocators.data[94] = i94;
      allocators.data[95] = i95;
      allocators.data[96] = i96;
      allocators.data[97] = i97;
      allocators.data[98] = i98;
      allocators.data[99] = i99;

      methodThunks = new Array<ForeignMethodFn>();
      methodThunks.set_size(100);
      methodThunks.data[0] = c0;
      methodThunks.data[1] = c1;
      methodThunks.data[2] = c2;
      methodThunks.data[3] = c3;
      methodThunks.data[4] = c4;
      methodThunks.data[5] = c5;
      methodThunks.data[6] = c6;
      methodThunks.data[7] = c7;
      methodThunks.data[8] = c8;
      methodThunks.data[9] = c9;
      methodThunks.data[10] = c10;
      methodThunks.data[11] = c11;
      methodThunks.data[12] = c12;
      methodThunks.data[13] = c13;
      methodThunks.data[14] = c14;
      methodThunks.data[15] = c15;
      methodThunks.data[16] = c16;
      methodThunks.data[17] = c17;
      methodThunks.data[18] = c18;
      methodThunks.data[19] = c19;
      methodThunks.data[20] = c20;
      methodThunks.data[21] = c21;
      methodThunks.data[22] = c22;
      methodThunks.data[23] = c23;
      methodThunks.data[24] = c24;
      methodThunks.data[25] = c25;
      methodThunks.data[26] = c26;
      methodThunks.data[27] = c27;
      methodThunks.data[28] = c28;
      methodThunks.data[29] = c29;
      methodThunks.data[30] = c30;
      methodThunks.data[31] = c31;
      methodThunks.data[32] = c32;
      methodThunks.data[33] = c33;
      methodThunks.data[34] = c34;
      methodThunks.data[35] = c35;
      methodThunks.data[36] = c36;
      methodThunks.data[37] = c37;
      methodThunks.data[38] = c38;
      methodThunks.data[39] = c39;
      methodThunks.data[40] = c40;
      methodThunks.data[41] = c41;
      methodThunks.data[42] = c42;
      methodThunks.data[43] = c43;
      methodThunks.data[44] = c44;
      methodThunks.data[45] = c45;
      methodThunks.data[46] = c46;
      methodThunks.data[47] = c47;
      methodThunks.data[48] = c48;
      methodThunks.data[49] = c49;
      methodThunks.data[50] = c50;
      methodThunks.data[51] = c51;
      methodThunks.data[52] = c52;
      methodThunks.data[53] = c53;
      methodThunks.data[54] = c54;
      methodThunks.data[55] = c55;
      methodThunks.data[56] = c56;
      methodThunks.data[57] = c57;
      methodThunks.data[58] = c58;
      methodThunks.data[59] = c59;
      methodThunks.data[60] = c60;
      methodThunks.data[61] = c61;
      methodThunks.data[62] = c62;
      methodThunks.data[63] = c63;
      methodThunks.data[64] = c64;
      methodThunks.data[65] = c65;
      methodThunks.data[66] = c66;
      methodThunks.data[67] = c67;
      methodThunks.data[68] = c68;
      methodThunks.data[69] = c69;
      methodThunks.data[70] = c70;
      methodThunks.data[71] = c71;
      methodThunks.data[72] = c72;
      methodThunks.data[73] = c73;
      methodThunks.data[74] = c74;
      methodThunks.data[75] = c75;
      methodThunks.data[76] = c76;
      methodThunks.data[77] = c77;
      methodThunks.data[78] = c78;
      methodThunks.data[79] = c79;
      methodThunks.data[80] = c80;
      methodThunks.data[81] = c81;
      methodThunks.data[82] = c82;
      methodThunks.data[83] = c83;
      methodThunks.data[84] = c84;
      methodThunks.data[85] = c85;
      methodThunks.data[86] = c86;
      methodThunks.data[87] = c87;
      methodThunks.data[88] = c88;
      methodThunks.data[89] = c89;
      methodThunks.data[90] = c90;
      methodThunks.data[91] = c91;
      methodThunks.data[92] = c92;
      methodThunks.data[93] = c93;
      methodThunks.data[94] = c94;
      methodThunks.data[95] = c95;
      methodThunks.data[96] = c96;
      methodThunks.data[97] = c97;
      methodThunks.data[98] = c98;
      methodThunks.data[99] = c99;
    } // ctor
  }
}