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
   * In wrennull.c.
   */
  public extern GLib.Type get_null_type();

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
    if(!static_init_done) {
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

    public errordomain MarshalError {
      /** Slot or other item not found */
      ENOENT,
    }

    /**
     * Wrap a single Wren slot in a GValue.
     *
     * The mapping is:
     * * Wren BOOL -> GLib.Type.BOOLEAN
     * * Wren NULL -> GLib.Type.NONE
     *
     * @param vm          The vm to read from
     * @param slot        The slot to grab.  It must exist.
     */
    public Value to_value_raw(Wren.VM vm, int slot)
    {
      var ty = vm.GetSlotType(slot);

      switch(ty) {
      case BOOL:
        return vm.GetSlotBool(slot);
      case NUM:
        return vm.GetSlotDouble(slot);
      case FOREIGN:
        // TODO
        break;
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
        assert_not_reached();
      }

      return Value(GLib.Type.INVALID);
    }

    /**
     * Wrap Wren slots in a GValue array.
     *
     * @param vm          The vm to read from
     * @param first_slot  The first slot to grab (default 0)
     * @param num_slots   How many slots to grab (default -1 == the whole
     *                    slot array)
     * @return An array of freshly-created GValues.
     */
    public Value[] to_values_raw(Wren.VM vm, int first_slot = 0, int num_slots = -1)
    throws MarshalError
    {
      if(num_slots == -1) {
        num_slots = vm.GetSlotCount();
      }

      if(first_slot + num_slots >= vm.GetSlotCount()) {
        throw new MarshalError.ENOENT(
                "Slots up to %d requested, but only %d are available".printf(
                  first_slot + num_slots, vm.GetSlotCount()));
      }

      Value[] retval = new Value[num_slots];
      for(int i=0; i<num_slots; ++i) {
        int curr_slot = first_slot + i;
        retval[i] = to_value_raw(vm, curr_slot);
      }

      return retval;
    }
  }
} // namespace Wren
