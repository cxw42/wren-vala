// basics.vapi: Vala bindings for Wren.
// Documentation is taken from wren.h (license below).  This file is in the
// same order as wren.h, as of writing.
// See vm.vala for convenience classes Wren.HandleV and Wren.VMV.
//
// By Christopher White <cxwembedded@gmail.com>
// SPDX-License-Identifier: MIT
//
// TODO: check the ownership on Handle instances.

[CCode(cheader_filename = "wren-vala-merged.h", lower_case_cprefix="wren")]
namespace Wren {

  [CCode(cname="WREN_VERSION_MAJOR")]
  extern int VERSION_MAJOR;
  [CCode(cname="WREN_VERSION_MINOR")]
  extern int VERSION_MINOR;
  [CCode(cname="WREN_VERSION_PATCH")]
  extern int VERSION_PATCH;
  [CCode(cname="WREN_VERSION_NUMBER")]
  extern int VERSION_NUMBER;

  /** Handle to a Wren object */
  [CCode(free_function = "", has_type_id = false)]
  [Compact]
  public extern class Handle
  {
  }

  [CCode(delegate_target_pos = 2)]
  public delegate void *ReallocateFn(void *memory, size_t newSize);

  [CCode(has_target = false)]
  public delegate void ForeignMethodFn(VM vm, void *userData);

  [CCode(has_target = false)]
  public delegate void FinalizerFn(void *data, void *userData);

  [CCode(has_target = false)]
  public delegate string ResolveModuleFn(VM vm, string importer, string name);

  [CCode(has_target = false)]
  public delegate void LoadModuleCompleteFn(VM vm, string name, LoadModuleResult result);

  [SimpleType]
  public struct LoadModuleResult
  {
    string source;
    LoadModuleCompleteFn onComplete;
    void *userData;
  }

  [CCode(has_target = false)]
  public delegate LoadModuleResult LoadModuleFn(VM vm, string name);

  [SimpleType]
  public struct BindForeignMethodResult
  {
    ForeignMethodFn executeFn;
    void* userData;
  }

  [CCode(has_target = false)]
  public delegate BindForeignMethodResult BindForeignMethodFn(VM vm, string module,
    string className,
    bool isStatic,
    string signature);

  [CCode(has_target = false)]
  public delegate void WriteFn(VM vm, string text);

  [CCode(cprefix = "WREN_ERROR_", has_type_id = false)]
  public enum ErrorType
  {
    COMPILE,
    RUNTIME,
    STACK_TRACE,
  }

  /**
   * Reports an error to the user.
   *
   * An error detected during compile time is reported by calling this once with
   * [type] `WREN_ERROR_COMPILE`, the resolved name of the [module] and [line]
   * where the error occurs, and the compiler's error [message].
   *
   * A runtime error is reported by calling this once with [type]
   * `WREN_ERROR_RUNTIME`, no [module] or [line], and the runtime error's
   * [message]. After that, a series of [type] `WREN_ERROR_STACK_TRACE` calls are
   * made for each line in the stack trace. Each of those has the resolved
   * [module] and [line] where the method or function is defined and [message] is
   * the name of the method or function.
   *
   * @param vm      The VM
   * @param type    The type of error
   * @param module  For compile errors and stack traces, the module.
   *                For runtime errors, NULL.
   * @param line    The line number (not used for runtime errors)
   * @param message The error message
   */
  [CCode(has_target = false)]
  public delegate void ErrorFn(VM vm, ErrorType type, string? module,
    int line, string message);

  // Has to be a SimpleType so it can be returned by value from functions.
  [SimpleType]
  public struct ForeignClassMethods
  {
    ForeignMethodFn allocate;
    void *allocateUserData;
    FinalizerFn finalize;
    void *finalizeUserData;
  }

  [CCode(has_target = false)]
  public delegate ForeignClassMethods BindForeignClassFn(VM vm, string module, string className);

  /** Virtual-machine configuration */
  [CCode(destroy_function = "")]
  public struct Configuration
  {
    ReallocateFn reallocateFn;
    ResolveModuleFn resolveModuleFn;
    LoadModuleFn loadModuleFn;
    BindForeignMethodFn bindForeignMethodFn;
    BindForeignClassFn bindForeignClassFn;
    WriteFn writeFn;
    ErrorFn errorFn;
    size_t initialHeapSize;
    size_t minHeapSize;
    int heapGrowthPercent;
    void *userData;

    public static Configuration default ()
    {
      var retval = Configuration();
      InitConfiguration(ref retval);
      return retval;
    }
  }

  [CCode(cprefix="WREN_RESULT_", has_type_id = "false")]
  public enum InterpretResult
  {
    SUCCESS,
    COMPILE_ERROR,
    RUNTIME_ERROR,
  }

  [CCode(cprefix="WREN_TYPE_", has_type_id = "false")]
  public enum Type {
    BOOL, NUM, FOREIGN, LIST, MAP, NULL, STRING, UNKNOWN,
  }

  public extern void InitConfiguration(ref Configuration configuration);

  /**
   * Virtual machine.
   *
   * This class includes all functions taking a WrenVM as the first parameter.
   */
  [CCode(cheader_filename = "wren-vala-merged.h", free_function = "wrenFreeVM",
    has_type_id = false, cprefix="wren", lower_case_cprefix="wren")]
  [Compact]
  public class VM
  {
    /** Constructor */
    [CCode(cname = "wrenNewVM")]
    public extern VM(Configuration? config = null);

    public extern void CollectGarbage();

    public extern InterpretResult Interpret(string module, string source);

    /**
     * Create a new handle for a method of the given signature.
     *
     * The resulting handle can be used with any receiver that provides
     * a function matching that signature.
     */
    public extern Handle MakeCallHandle(string signature);

    public extern InterpretResult Call(Handle method);

    public extern void ReleaseHandle(owned Handle handle);

    public extern int GetSlotCount();
    public extern void EnsureSlots(int numSlots);

    public extern Wren.Type GetSlotType(int slot);
    public extern bool GetSlotBool(int slot);
    public extern unowned uint8[] GetSlotBytes(int slot);
    public extern double GetSlotDouble(int slot);
    public extern void *GetSlotForeign(int slot);
    public extern unowned string GetSlotString(int slot);

    /** Create a new handle for the value in the given slot */
    public extern Handle GetSlotHandle(int slot);

    public extern void SetSlotBool(int slot, bool value);
    public extern void SetSlotBytes(int slot, uint8[] bytes);
    public extern void SetSlotDouble(int slot, double value);
    public extern void *SetSlotNewForeign(int slot, int classSlot, size_t size);
    public extern void SetSlotNewList(int slot);
    public extern void SetSlotNewMap(int slot);
    public extern void SetSlotNull(int slot);
    public extern void SetSlotString(int slot, string text);
    public extern void SetSlotHandle(int slot, Handle handle);

    public extern int GetListCount(int slot);
    public extern void GetListElement(int listSlot, int index, int elementSlot);
    public extern void SetListElement(int listSlot, int index, int elementSlot);
    public extern void InsertInList(int listSlot, int index, int elementSlot);

    public extern int GetMapCount(int slot);
    public extern int GetMapContainsKey(int mapSlot, int keySlot);
    public extern void GetMapValue(int mapSlot, int keySlot, int elementSlot);
    public extern void SetMapValue(int mapSlot, int keySlot, int elementSlot);
    public extern void RemoveMapValue(int mapSlot, int keySlot, int removedValueSlot);

    public extern void GetVariable(string module, string name, int slot);
    public extern bool HasVariable(string module, string name);

    public extern bool HasModule(string module);

    public extern void AbortFiber(int slot);

    public extern void *GetUserData();
    public extern void SetUserData(void *userData);
  } // class VM

} // namespace Wren
