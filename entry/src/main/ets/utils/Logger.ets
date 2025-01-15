// SPDX-License-Identifier: GPL-3.0-or-later
import hilog from '@ohos.hilog'

export class Logger {
    static Debug(component: string, message: string) {
        hilog.debug(0x0000, component, message)
    }

    static Info(component: string, message: string) {
        hilog.info(0x0000, component, message)
    }

    static Warn(component: string, message: string) {
        hilog.warn(0x0000, component, message)
    }

    static Error(component: string, message: string) {
        hilog.error(0x0000, component, message)
    }
}
