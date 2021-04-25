// shim.c: wren-vala routines that are easier to implement in C
//
// Currently contains:
// - A GType representing Wren's null type
// - Object** manipulation
//
// By Christopher White <cxwembedded@gmail.com>
// Copyright (c) 2021 Christopher White.  All Rights Reserved.
// SPDX-License-Identifier: MIT

#include <glib.h>
#include <glib-object.h>
#include "wren-vala-merged.h"

G_BEGIN_DECLS

// Stub functions for GValue holding a WrenNull

static void value_nop(GValue *v)
{
}

static void value_nop2(const GValue *s, GValue *d)
{
}

static gchar *value_collect_nop(GValue *value, guint n_collect_values,
  GTypeCValue *collect_values,
  guint collect_flags)
{
  return (gchar *)NULL;
}

static gchar *value_collect_nop_const(const GValue *value, guint n_collect_values,
  GTypeCValue *collect_values,
  guint collect_flags)
{
  return (gchar *)NULL;
}

/**
 * wrennull_get_type_once:
 *
 * Register a fundamental type representing Wren's null value.
 * Thanks to glib's _g_value_types_init() and to Vala's get_type_once output
 * for explanation of what to do in this function.
 *
 * A GValue of this type has no data; the GType itself represents the Wren null.
 *
 * Return: The GType
 */
static GType
wrennull_get_type_once(void)
{
  static const GTypeValueTable g_define_type_value_table = {
    value_nop,  // init
    value_nop,  // free
    value_nop2, // copy
    NULL,       // peek_pointer
    "i",        // collect format
    value_collect_nop,
    "p",        // lcopy format
    value_collect_nop_const,
  };

  static const GTypeInfo g_define_type_info = {
    0,
    (GBaseInitFunc)NULL,
    (GBaseFinalizeFunc)NULL,
    (GClassInitFunc)NULL,
    (GClassFinalizeFunc)NULL,
    NULL,
    0,
    0,
    (GInstanceInitFunc)NULL,
    &g_define_type_value_table
  };

  static const GTypeFundamentalInfo g_define_type_fundamental_info = {
    G_TYPE_FLAG_DERIVABLE
  };

  GType wrennull_type_id;
  wrennull_type_id = g_type_register_fundamental(
    g_type_fundamental_next(), "wren-null", &g_define_type_info,
    &g_define_type_fundamental_info, 0);

  return wrennull_type_id;
}

GType
wrenget_null_type()
{
  static volatile gsize wrennull_type_id__volatile = 0;
  if (g_once_init_enter(&wrennull_type_id__volatile)) {
    GType wrennull_type_id;
    wrennull_type_id = wrennull_get_type_once();
    g_once_init_leave(&wrennull_type_id__volatile, wrennull_type_id);
  }
  return wrennull_type_id__volatile;
}

/**
 * wrenobj_from_ppobj:
 * @ppobj: (transfer none): A GObject**, as a void*
 *
 * Does not touch the refcount of **ppobj.  This exists because it was faster
 * to write this function than to debug the compile-time errors I was getting
 * when I tried to do the same in Vala! :)
 *
 * Return: (transfer none): A GObject*
 */
GObject *wrenobj_from_ppobj(void *ppobj)
{
  return *(GObject **)ppobj;
}

G_END_DECLS
