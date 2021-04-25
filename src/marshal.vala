// marshal.vala: Wren<->Vala marshalling
//
// By Christopher White <cxwembedded@gmail.com>
// Copyright (c) 2021 Christopher White.  All rights reserved.
// SPDX-License-Identifier: MIT

[CCode(cheader_filename="wren-vala-merged.h")]
namespace Wren {

  /**
   * Vala type representing the Wren null value.
   *
   * We use this because you can't create {@link GLib.Value}s of
   * {@link GLib.Type.NONE}.
   *
   * Defined in shim.c.
   */
  public extern GLib.Type get_null_type();

  /**
   * Convert GObject** to GObject*
   *
   * Defined in shim.c.
   */
  private extern unowned Object obj_from_ppobj(void *ppobj);

  /**
   * Initialize the Wren Vala bindings.
   *
   * Call this before calling any of the marshalling functions.
   * {@link Wren.VMV}'s constructors call this for you.
   *
   * Idempotent.
   */
  public void static_init()
  {
    if(static_init_done) {
      return;
    }

    // At the moment, this function is somewhat pointless, since the only
    // thing in here is the idempotent initialization of the wren-null type.
    // However, leaving the function here means that we won't have to change
    // the API if we have to add more initialization steps in the future.

    get_null_type();
    static_init_done = true;
  }
  private bool static_init_done = false;

  [CCode(cheader_filename="wren-vala-merged.h")]
  namespace Marshal {

    public errordomain Error {
      /** Slot or other item not found */
      ENOENT,
      /** Unknown type, or type I can't handle */
      ENOTSUP,
      /** Forbidden by the language (can't be fixed by a wren-vala change) */
      EINVAL,
    }

    // === Wren -> Vala =============================================

    /**
     * Get a GLib.Value from a single Wren slot.
     *
     * The mapping is:
     *
     *  * Wren BOOL -> GLib.Type.BOOLEAN
     *  * Wren NUM -> double
     *  * Wren FOREIGN -> GLib.Object (this assumes you don't create any
     *    objects using something other than wren-vala)
     *  * Wren STRING -> string
     *  * Wren NULL -> Wren.get_null_type()
     *
     * @param vm          The vm to read from
     * @param slot        The slot to grab.  It must exist.
     */
    public Value value_from_slot(Wren.VM vm, int slot)
    throws Marshal.Error
    {
      var ty = vm.GetSlotType(slot);

      switch(ty) {
      case BOOL:
        return vm.GetSlotBool(slot);
      case NUM:
        return vm.GetSlotDouble(slot);
      case FOREIGN:
        var retval = Value(GLib.Type.OBJECT);
        var obj = obj_from_ppobj(vm.GetSlotForeign(slot));
        retval.set_object(obj); // adds a ref
        return retval;
      case LIST:
        // TODO
        break;
      case MAP:
        // TODO
        break;
      case NULL:
        return Value(get_null_type());
      case STRING:
        return vm.GetSlotString(slot);
      case UNKNOWN:
        // TODO
        break;
      default:
        break;
      }

      throw new Marshal.Error.ENOTSUP(
              "I don't know how to send type Wren %s to Vala".printf(ty.to_string()));
    } // value_from_slot

    /**
     * Wrap Wren slots in a GValue array.
     *
     * @param vm          The vm to read from
     * @param first_slot  The first slot to grab (default 0)
     * @param num_slots   How many slots to grab (default -1 == the whole
     *                    slot array)
     * @return An array of freshly-created GValues.
     */
    public Value[] values_from_slots(Wren.VM vm, int first_slot = 0, int num_slots = -1)
    throws Marshal.Error
    {
      if(num_slots == -1) {
        num_slots = vm.GetSlotCount();
      }

      if(first_slot + num_slots > vm.GetSlotCount()) {
        throw new Marshal.Error.ENOENT(
                "Slots up to %d requested, but only %d are available".printf(
                  first_slot + num_slots, vm.GetSlotCount()));
      }

      Value[] retval = new Value[num_slots];
      for(int i=0; i<num_slots; ++i) {
        int curr_slot = first_slot + i;
        retval[i] = value_from_slot(vm, curr_slot);
      }

      return retval;
    } // values_from_slots()

    // === Vala -> Wren =============================================

    /**
     * Fill a Wren slot from a GValue.
     *
     *  * Bool, number, and string are passed straight through.
     *  * Object is invalid --- there's no way to load an instance
     *    you didn't create in Wren.
     *
     * @param vm    The VM
     * @param slot  Slot to set
     * @param val   New value
     */
    public void slot_from_value(Wren.VM vm, int slot, Value val)
    throws Marshal.Error
    {
      var vty = val.type();

      if(vty == get_null_type()) {
        // Outside the switch because it's not a compile-time constant
        vm.SetSlotNull(slot);
        return;
      }

      switch(vty) {
      case GLib.Type.BOOLEAN:
        vm.SetSlotBool(slot, val.get_boolean());
        return;
      case GLib.Type.DOUBLE:
      case GLib.Type.FLOAT:
      case GLib.Type.INT:
      case GLib.Type.INT64:
      case GLib.Type.LONG:
      case GLib.Type.UINT:
      case GLib.Type.UINT64:
      case GLib.Type.ULONG:
        var dblval = Value(GLib.Type.DOUBLE);
        val.transform(ref dblval);
        vm.SetSlotDouble(slot, dblval.get_double());
        return;
      // FOREIGN: handled below
      // case LIST:
      //  // TODO
      //  break;
      // case MAP:
      //  // TODO
      //  break;
      case GLib.Type.STRING:
        vm.SetSlotString(slot, val.get_string());
        return;
      // case UNKNOWN:
      //  // TODO
      //  break;
      default:
        if(vty.is_object()) {
          throw new Marshal.Error.EINVAL("Cannot send Object instances to Wren");
        }
        break;
      }

      throw new Marshal.Error.ENOTSUP(
              "I don't know how to send Vala type %s to Wren".printf(vty.to_string()));
    } // set_slot()

  } // namespace Marshal

} // namespace Wren
