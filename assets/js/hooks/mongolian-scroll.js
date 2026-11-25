/**
 * Ensures mgl-common-ui's global scroll runtime is active after LiveView mounts.
 * Do not also call bindSurface() here: install() already delegates wheel/keyboard/drag globally.
 */
import {install} from "mgl-common-ui"

export const MongolianScroll = {
  mounted() {
    install({selector: ".mn-surface"})
  },
}
