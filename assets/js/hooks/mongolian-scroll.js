/**
 * Wheel / keyboard / drag for vertical-lr `.mn-surface` shells.
 * Runtime lives in mgl-common-ui; this hook keeps phx-hook="MongolianScroll"
 * markup from erroring and rebinds after LiveView morphs.
 */
import {install, bindSurface} from "mgl-common-ui"

let globalInstalled = false

function ensureGlobalInstall() {
  if (globalInstalled) return
  install({selector: ".mn-surface"})
  globalInstalled = true
}

export const MongolianScroll = {
  mounted() {
    ensureGlobalInstall()
    this._stop = bindSurface(this.el, {keyboard: true, drag: true})
  },
  destroyed() {
    if (this._stop) this._stop()
  },
}
