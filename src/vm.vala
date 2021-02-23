// vm.vala: Vala bindings for WrenVM
// See wren.h for documentation.
//
// By Christopher White <cxwembedded@gmail.com>
// SPDX-License-Identifier: MIT
//
// TODO: check the ownership on Handle instances.

// **************************************************************************
// *** We cannot use @APIVER@ here since asking ./configure to regenerate ***
// *** Vala files would prevent building on machines without valac(1).    ***
// *** Therefore, whenever you change the version, update `0.4.0` to      ***
// *** match the new version throughout this file.                        ***
// **************************************************************************

[CCode(cheader_filename="libwren-vala-0.4.0.h,wren.h")]
namespace Wren {

  /**
   * Reference-counted wrapper for Handle.
   *
   * Use this instead of a bare Handle whenever possible.
   */
  [CCode(cheader_filename="libwren-vala-0.4.0.h,wren.h")]
  public class HandleAuto
  {
    private unowned VM vm;
    private Handle handle;

    internal unowned Handle GetHandle()
    {
      return handle;
    }

    public HandleAuto(VM vm, owned Handle handle)
    {
      this.vm = vm;
      this.handle = (owned)handle;
    }

    ~HandleAuto()
    {
      vm.ReleaseHandle((owned)handle);
    }
  }

  /**
   * Virtual machine, with HandleAuto (VMV = "VM - Vala")
   *
   * This class extends {@link Wren.VM} with {@link Wren.HandleAuto}
   * equivalents of all the {@link Wren.Handle} functions.
   */
  [CCode(cheader_filename = "libwren-vala-0.4.0.h,wren.h")]
  public class VMV : VM
  {
    public VMV(Configuration? config = null)
    {
      base(config);
    }

    /** Make a HandleAuto for a function */
    public HandleAuto MakeCallHandleAuto(string signature)
    {
      return new HandleAuto(this, MakeCallHandle(signature));
    }

    public InterpretResult CallAuto(HandleAuto method)
    {
      return Call(method.GetHandle());
    }

    public HandleAuto GetSlotHandleAuto(int slot)
    {
      return new HandleAuto(this, GetSlotHandle(slot));
    }

    public void SetSlotHandleAuto(int slot, HandleAuto handle)
    {
      SetSlotHandle(slot, handle.GetHandle());
    }

  } // class VMV
} // namespace Wren
