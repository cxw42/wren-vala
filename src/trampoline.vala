// trampoline.vala: Functions for class bindings
// Part of wren-vala
// By Christopher White <cxwembedded@gmail.com>
// SPDX-License-Identifier: MIT

[CCode(cheader_filename="wren-vala-merged.h")]
namespace Wren {

  /**
   * Record describing a property
   *
   * This is used as the userData parameter for property-get and
   * property-set calls.
   */
  [Compact]
  private class PropertyDescriptor
  {
    /** The name of the property */
    public string name;
    /** The type of the property, cached for speed. */
    public GLib.Type type;
    /** True if it's a setter --- for convenience */
    public bool is_setter;

    public PropertyDescriptor(string newname, GLib.Type newtype, bool new_is_setter)
    {
      name = newname;
      type = newtype;
      is_setter = new_is_setter;
    }
  } // class PropertyDescriptor

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
     * Types we can instantiate
     *
     * Maps from {@link hash_key()} of the class to {@link GLib.Type}.
     */
    HashTable<string, GLib.Type> types_ =
      new HashTable<string, GLib.Type>(str_hash, str_equal);

    /**
     * Functions that implement methods.
     *
     * Map from {@link hash_key()} of the method to static function.
     */
    HashTable<string, HasMethods.MethodImpl> methodImpls =
      new HashTable<string, HasMethods.MethodImpl>(str_hash, str_equal);

    /**
     * Properties we know about.
     *
     * Map from {@link hash_key()} of the property accessor ({{{foo}}} or
     * {{{foo=}}}) to descriptor.
     */
    HashTable<string, PropertyDescriptor> props_ =
      new HashTable<string, PropertyDescriptor>(str_hash, str_equal);

    // --- Public interface ---------------------------------------

    /**
     * Make a hash key for a class or method.
     *
     * * You must not specify signature for a class.
     * * You must specify signature for a method.
     *
     * @param module    Name of the module
     * @param className Name of the class
     * @param signature The signature.  For static methods, signature should
     *                  begin with {{{static }}}.
     */
    public static string hash_key(string module, string className,
      string? signature = null)
    {
      if(signature == null) {
        return @"$module!$className";
      } else {

        return @"$module!$className:$signature";
      }
    }

    /**
     * Return the allocator and finalizer functions for a type.
     */
    public ForeignClassMethods get_class_methods(string module, string className)
    {
      ForeignClassMethods retval = {};

      var key = hash_key(module, className);
      if(types_.contains(key)) {
        retval.allocate = allocate_instance;
        retval.allocateUserData = (void *)types_[key];
        retval.finalize = deallocateObject;
        retval.finalizeUserData = null;
        debug("Functions for %s: %p, %p; userdata %p = %s", key,
          &retval.allocate, &retval.finalize, retval.allocateUserData,
          types_[key].name());
      }
      return retval;
    } // get_class_methods()

    /**
     * Get a method of a class.
     */
    public BindForeignMethodResult get_method(string module, string className,
      bool isStatic, string signature)
    {
      BindForeignMethodResult retval = {};

      var key = hash_key(module, className, make_sig(isStatic, signature));

      // property gets/sets
      if(props_.contains(key) && props_[key].is_setter) {
        retval.executeFn = set_property_;
        retval.userData = (void *)(props_[key]);

      } else if(props_.contains(key) && !props_[key].is_setter) {
        retval.executeFn = get_property_;
        retval.userData = (void *)(props_[key]);

      } else if (methodImpls.contains(key)) {

        // methods
        retval.executeFn = call_method;
        retval.userData = (void *)methodImpls[key];
        debug("Function for %s: %p, userdata %p", key,
          &retval.executeFn, retval.userData);

      } else {
        // TODO better error handling
        error("No foreign-method implementation or foreign property found for key %s", key);
      }

      return retval;
    } // get_method()

    private static void foreach_method_of_type(GLib.Type type,
      GLib.HFunc<string,HasMethods.MethodImpl> callback)
    {
      var instance = Object.new(type);
      assert(instance != null);
      var has_methods = instance as HasMethods;
      if(has_methods != null) {
        debug("Getting methods of %s", type.name());
        var methods = new HashTable<string, HasMethods.MethodImpl>(str_hash, str_equal);
        has_methods.get_methods(ref methods);
        methods.foreach(callback);
      }
    } // foreach_method_of_type()

    /**
     * Add a type.
     *
     * Idempotent.
     * @param module    The module to load the class into
     * @param className The Wren-visible name of the class
     * @param type      The GLib type of the class
     *
     * @return  The Wren source for the class, or "" if the class was
     *          previously registered.
     */
    public string add_type(string module, string className, GLib.Type type)
    {
      var type_key = hash_key(module, className);

      if(types_.contains(type_key)) {
        return "";
      }

      types_[type_key] = type;

      debug("Class %s is %s", type_key, types_[type_key].name());

      var wren_source = new StringBuilder();
      wren_source.append_printf("foreign class %s {\n", type.name());
      wren_source.append("construct new() {}\n");

      debug("Loading methods");
      foreach_method_of_type(type, (sig, impl) => {
        methodImpls[hash_key(module, className, sig)] = impl;
        wren_source.append(foreign_decl_for(sig) + "\n");
      });

      debug("Loading properties");
      ObjectClass ocl = (ObjectClass)type.class_ref();

      foreach (ParamSpec spec in ocl.list_properties()) {

        // Getter
        if((spec.flags & GLib.ParamFlags.READABLE) != 0) {
          var propsig = spec.name;
          var propkey = hash_key(module, className, propsig);
          wren_source.append_printf("foreign %s\n", propsig);
          props_[propkey] = new PropertyDescriptor(spec.name, spec.value_type, false);
        }

        // Setter
        if((spec.flags & GLib.ParamFlags.WRITABLE) != 0) {
          var propsig = spec.name + "=(_)"; // setter
          var propkey = hash_key(module, className, propsig);
          wren_source.append_printf("foreign %s=(p0)\n", spec.name);
          props_[propkey] = new PropertyDescriptor(spec.name, spec.value_type, true);
        }

      } // foreach property

      wren_source.append("}\n");

      return wren_source.str;
    } // add_type()

    // --- Allocating and deallocating instances ------------------

    /**
     * Instantiate an instance of a foreign class
     *
     * @param vm    The Wren VM to use
     * @param index The index in {@link types_} to use.
     */
    private static void allocate_instance(VM vm, void *userData)
    {
      var type = (GLib.Type)userData;
      debug("instantiate: vm %p, userdata %p => type %s",
        vm, userData, type.name());

      // Do the work!
      var instance = Object.new(type);

      // ref() to counteract the automatic unref() at the end of this function
      instance.ref ();

      // Give the instance to Wren
      unowned Object **ppobject = (Object **)vm.SetSlotNewForeign(0, 0, sizeof(Object));
      *ppobject = instance;

      debug("New %s is %p", type.name(), instance);
    }

    /** Free a GObject instance */
    private static void deallocateObject(void *data, void *userData)
    {
      unowned Object **ppobject = (Object **)data;
      debug("deallocateObject %p\n", ppobject);
      if(ppobject != null) {
        unowned Object *obj = *ppobject;
        obj->unref();
      }
    }

    // --- Interacting with instances -----------------------------

    /**
     * Call a method on a class instance
     *
     * This is a {@link Wren.ForeignMethodFn}.
     *
     * @param vm        The Wren VM to use
     * @param userData  The {@link HasMethods.MethodImpl} that will handle
     *                  this function call
     */
    private static void call_method(VM vm, void *userData)
    {
      var fn = (HasMethods.MethodImpl)userData;
      debug("call_method: vm %p, fn %p", vm, &fn);

      unowned Object **ppobject = (Object **)vm.GetSlotForeign(0);
      var vmv = vm.GetUserData() as Wren.VMV;
      fn(*ppobject, vmv);
    }

    /**
     * Get a property on a class instance
     *
     * This is a {@link Wren.ForeignMethodFn}.
     *
     * @param vm        The Wren VM to use
     * @param userData  An unowned pointer to the {@link PropertyDescriptor}
     *                  for this property.
     */
    private static void get_property_(VM vm, void *userData)
    {
      unowned PropertyDescriptor prop = (PropertyDescriptor)userData;
      debug("get property: vm %p, %s %s", vm, prop.type.name(), prop.name);

      unowned Object **ppobject = (Object **)vm.GetSlotForeign(0);
      var val = Value(prop.type);
      (*ppobject)->get_property(prop.name, ref val);
      try {
        Marshal.slot_from_value(vm, 0, val);
      } catch(Marshal.Error e) {
        error("marshalling error while getting property %s: %s", prop.name, e.message);
      }
    }

    /**
     * Set a property on a class instance
     *
     * This is a {@link Wren.ForeignMethodFn}.
     *
     * @param vm        The Wren VM to use
     * @param userData  An unowned pointer to the {@link PropertyDescriptor}
     *                  for this property.
     */
    private static void set_property_(VM vm, void *userData)
    {
      unowned PropertyDescriptor prop = (PropertyDescriptor)userData;
      debug("set property: vm %p, %s %s", vm, prop.type.name(), prop.name);

      unowned Object **ppobject = (Object **)vm.GetSlotForeign(0);
      Value val;
      try {
        val = Marshal.value_from_slot(vm, 1);
      } catch(Marshal.Error e) {
        error("marshalling error while setting property %s: %s", prop.name, e.message);
      }
      (*ppobject)->set_property(prop.name, val);
    }

  } // class Tramp
} // namespace Wren
