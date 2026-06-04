#include <stddef.h>
#include <wayland-util.h>

/*
 * wlr-layer-shell references xdg_popup in the get_popup request. This MVP does
 * not create popups yet, but wayland-scanner still emits a type reference that
 * must be linkable to keep the real protocol request order intact.
 */
const struct wl_interface xdg_popup_interface = {
    "xdg_popup",
    1,
    0,
    NULL,
    0,
    NULL,
};
