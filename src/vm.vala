// vm.vala: Vala bindings for WrenVM
// See wren-pkg/wren/src/include/wren.h for documentation.
//
// By Christopher White <cxwembedded@gmail.com>
// Copyright (c) 2021 Christopher White.  All rights reserved.
// SPDX-License-Identifier: MIT
//
// TODO: check the ownership on Handle instances.

[CCode(cheader_filename="wren-vala-merged.h")]
namespace Wren {

  /**
   * Reference-counted wrapper for Handle (Handle, Vala).
   *
   * Use this instead of a bare Handle whenever possible.
   */
  [CCode(cheader_filename="wren-vala-merged.h")]
  public class HandleV
  {
    private VMV vm;
    private Handle handle;

    internal unowned Handle get_handle()
    {
      return handle;
    }

    public HandleV(VMV vm, owned Handle handle)
    {
      this.vm = vm;
      this.handle = (owned)handle;
    }

    ~HandleV()
    {
      vm.release_handle((owned)handle);
    }
  }

  /**
   * Print a message to stdout.
   *
   * This is the default writeFn for a {@link Wren.VMV}.
   */
  public void defaultWriteFn(VM vm, string text)
  {
    print("%s", text);
  }

  /**
   * Report an error to stderr.
   *
   * This is the default errorFn for a {@link Wren.VMV}.
   * Modified from wren-pkg/wren/example/embedding/main.c.
   */
  public void defaultErrorFn(VM vm, Wren.ErrorType errorType,
    string? module, int line, string msg)
  {
    switch (errorType)
    {
    case COMPILE:
      printerr("[%s line %d] [Error] %s\n", module, line, msg);
      break;
    case STACK_TRACE:
      printerr("[%s line %d] in %s\n", module, line, msg);
      break;
    case RUNTIME:
      printerr("[Runtime Error] %s\n", msg);
      break;
    }
  }

  /**
   * Interface exposing functions to Wren
   *
   * This is used by {@link Wren.Tramp} to get the available methods.
   */
  public interface HasMethods : GLib.Object
  {
    /**
     * Implement a Wren method.
     *
     * @param self  The object instance (from Wren's foreign data)
     * @param vm    The Wren VM
     */
    [CCode(has_target = false)]
    public delegate void MethodImpl(GLib.Object self, VMV vm);

    /**
     * Fill a hash table with a map from {@link Wren.Tramp.hash_key} to
     * {@link Wren.HasMethods.MethodImpl}.
     *
     * Must be callable multiple times, returning the same value every time.
     * @param methods   An empty hash table to be filled
     */
    public abstract void get_methods(ref HashTable<string, MethodImpl> methods);
  } // interface HasMethods

  /**
   * Virtual machine, with HandleV (VMV = "VM - Vala")
   *
   * This class extends {@link Wren.VM} with {@link Wren.HandleV}
   * equivalents of all the {@link Wren.Handle} functions.
   *
   * It HAS-A Wren.VM instead of deriving from a Wren.VM so that it
   * can have Vala-esque naming conventions and reference counting.
   *
   * Functions in Wren.VM that use Wren.Handle arguments have
   * names in this class ending in `_raw`, e.g., call_raw().  The non-`_raw`
   * functions, e.g., call(), use Wren.HandleV arguments.  This is so the
   * default use of Handles is consistent with Vala memory management.
   */
  [CCode(cheader_filename="wren-vala-merged.h")]
  public class VMV : Object
  {
    // --- Instance data ------------------------------------------

    /** The wrapped Wren VM */
    private VM vm = null;

    /**
     * Trampolines
     *
     * Has to be public, but if you use it, your bindings will break!
     */
    [CCode(notify = false)]
    public Tramp tramp_ { get; private set; default = new Tramp(); }

    // --- VM functions -------------------------------------------

    /** Bind a foreign class */
    private static ForeignClassMethods bindForeignClass(VM vm, string module, string className)
    {
      var self = vm.GetUserData() as VMV;
      debug("bindForeignClass %s in %p\n",
        Tramp.hash_key(module, className), self);
      return self.tramp_.get_functions(module, className);
    }

    /** Bind a foreign method */
    private static ForeignMethodFn bindForeignMethod(VM vm, string module,
      string className, bool isStatic, string signature)
    {
      var self = vm.GetUserData() as VMV;
      debug("bindForeignMethod %s in %p\n",
        Tramp.hash_key(module, className, isStatic, signature), self);
      return self.tramp_.get_method(module, className, isStatic, signature);
    }

    // --- Constructors -------------------------------------------

    /** Create a VM with a particular configuration */
    public VMV.with_configuration(Configuration? config = null)
    {
      Wren.static_init();
      vm = new VM(config);
      vm.SetUserData(this);
    }

    // TODO support gobject-style construction?
    /**
     * Create a VM with a default configuration.
     *
     * The default is the Wren default configuration, plus a writeFn and
     * an errorFn modified from wren-pkg/wren/example/embedding/main.c,
     * and binding functions that support expose_class().
     */
    public VMV()
    {
      var conf = Wren.Configuration.default ();
      conf.writeFn = defaultWriteFn;
      conf.errorFn = defaultErrorFn;
      conf.bindForeignClassFn = bindForeignClass;
      conf.bindForeignMethodFn = bindForeignMethod;
      this.with_configuration(conf);
    }

    // --- Low-level interface ------------------------------------
    // This section exposes the Wren.VM methods.

    public void collect_garbage() {
      vm.CollectGarbage();
    }

    public InterpretResult interpret(string module, string source)
    {
      return vm.Interpret(module, source);
    }

    /**
     * Create a new handle for a method of the given signature.
     *
     * The resulting handle can be used with any receiver that provides
     * a function matching that signature.
     */
    public Handle make_call_handle_raw(string signature)
    {
      return vm.MakeCallHandle(signature);
    }

    /** Make a HandleV for a function */
    public HandleV make_call_handle(string signature)
    {
      return new HandleV(this, make_call_handle_raw(signature));
    }

    public InterpretResult call_raw(Handle method)
    {
      return vm.Call(method);
    }

    public InterpretResult call(HandleV method)
    {
      return call_raw(method.get_handle());
    }

    public void release_handle(owned Handle handle)
    {
      vm.ReleaseHandle((owned)handle);
    }

    public int get_slot_count()
    {
      return vm.GetSlotCount();
    }
    public void ensure_slots(int num_slots)
    {
      vm.EnsureSlots(num_slots);
    }

    public Wren.Type get_slot_type(int slot)
    {
      return vm.GetSlotType(slot);
    }
    public bool get_slot_bool(int slot)
    {
      return vm.GetSlotBool(slot);
    }
    public unowned uint8[] get_slot_bytes(int slot)
    {
      return vm.GetSlotBytes(slot);
    }
    public double get_slot_double(int slot)
    {
      return vm.GetSlotDouble(slot);
    }
    public void *get_slot_foreign(int slot)
    {
      return vm.GetSlotForeign(slot);
    }
    public unowned string get_slot_string(int slot)
    {
      return vm.GetSlotString(slot);
    }

    /** Create a new handle for the value in the given slot */
    public Handle get_slot_handle_raw(int slot)
    {
      return vm.GetSlotHandle(slot);
    }

    public HandleV get_slot_handle(int slot)
    {
      return new HandleV(this, get_slot_handle_raw(slot));
    }

    public void set_slot_bool(int slot, bool value)
    {
      vm.SetSlotBool(slot, value);
    }
    public void set_slot_bytes(int slot, uint8[] bytes)
    {
      vm.SetSlotBytes(slot, bytes);
    }
    public void set_slot_double(int slot, double value)
    {
      vm.SetSlotDouble(slot, value);
    }
    public void *set_slot_new_foreign(int slot, int class_slot, size_t size)
    {
      return vm.SetSlotNewForeign(slot, class_slot, size);
    }
    public void set_slot_new_list(int slot)
    {
      vm.SetSlotNewList(slot);
    }
    public void set_slot_new_map(int slot)
    {
      vm.SetSlotNewMap(slot);
    }
    public void set_slot_null(int slot)
    {
      vm.SetSlotNull(slot);
    }
    public void set_slot_string(int slot, string text)
    {
      vm.SetSlotString(slot, text);
    }
    public void set_slot_handle_raw(int slot, Handle handle)
    {
      vm.SetSlotHandle(slot, handle);
    }

    public void set_slot_handle(int slot, HandleV handle)
    {
      set_slot_handle_raw(slot, handle.get_handle());
    }

    public int get_list_count(int slot)
    {
      return vm.GetListCount(slot);
    }
    public void get_list_element(int list_slot, int index, int element_slot)
    {
      vm.GetListElement(list_slot, index, element_slot);
    }
    public void set_list_element(int list_slot, int index, int element_slot)
    {
      vm.SetListElement(list_slot, index, element_slot);
    }
    public void insert_inList(int list_slot, int index, int element_slot)
    {
      vm.InsertInList(list_slot, index, element_slot);
    }

    public int get_map_count(int slot)
    {
      return vm.GetMapCount(slot);
    }
    public int get_map_contains_key(int map_slot, int key_slot)
    {
      return vm.GetMapContainsKey(map_slot, key_slot);
    }
    public void get_map_value(int map_slot, int key_slot, int element_slot)
    {
      vm.GetMapValue(map_slot, key_slot, element_slot);
    }
    public void set_map_value(int map_slot, int key_slot, int element_slot)
    {
      vm.SetMapValue(map_slot, key_slot, element_slot);
    }
    public void remove_map_value(int map_slot, int key_slot, int removed_value_slot)
    {
      vm.RemoveMapValue(map_slot, key_slot, removed_value_slot);
    }

    public void get_variable(string module, string name, int slot)
    {
      vm.GetVariable(module, name, slot);
    }
    public bool has_variable(string module, string name)
    {
      return vm.HasVariable(module, name);
    }

    public bool has_module(string module)
    {
      return vm.HasModule(module);
    }

    public void abort_fiber(int slot)
    {
      vm.AbortFiber(slot);
    }

    // Userdata: private because VMV takes this for its own use.
#if 0
    private void *get_user_data()
    {
      return vm.GetUserData();
    }
    private void set_user_data(void *user_data)
    {
      vm.SetUserData(user_data);
    }
#endif

    // --- High-level interface -----------------------------------
    // This section binds classes as a whole between Vala and Wren

#if 0
    /**
     * Get a slot as a GValue
     */
    public Value get_slot(int slot)
    {
      // TODO
      return Value(GLib.Type.INVALID);
    }
#endif

    /**
     * Expose class T to Wren, as part of module `mod`
     *
     * @param mod The module to add the class to (default "main").
     */
    public InterpretResult expose_class<T>(string mod = "main")
    {
      StringBuilder wren = new StringBuilder(); // source to be interpreted
      var type = typeof(T);
      assert(!type.is_abstract()); // TODO more sophisticated error handling
      assert(type.is_instantiatable());

      // ObjectClass ocl = (ObjectClass)type.class_ref();

      wren.append_printf("foreign class %s {\n", type.name());

      // Properties
      // foreach (ParamSpec spec in ocl.list_properties()) {
      // TODO print ("%s\n", spec.get_name ());
      // }

      wren.append("construct new() {}\n");

      // Functions
      Tramp.foreach_method_of_type(type, (k,v) => {
        wren.append(Tramp.foreign_decl_for_key(k) + "\n");
      });

      wren.append("}\n");
      debug("Wren source: >>%s<<", wren.str);

      tramp_.add_type(mod, type.name(), type);

      return interpret(mod, wren.str);
    }

  } // class VMV
} // namespace Wren