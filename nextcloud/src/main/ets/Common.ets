import { Configuration } from "./nextcloud-api-sdk";
import { deviceInfo } from '@kit.BasicServicesKit'
import { preferences } from "@kit.ArkData";
import { common } from '@kit.AbilityKit';
import { Logger } from "./Logger";
import util from "@ohos.util";


const TAG = "Nextcloud-Common";

const USER_AGENT_PART = "Nextcloud Client for HarmonyOS on ";

class NPreference {
    private pref: preferences.Preferences;

    constructor(context: common.UIAbilityContext) {
        this.pref = preferences.getPreferencesSync(context, { name: "nextcloud" });
    }

    get password(): string {
        return this.getStringPref("login.appPassword") ?? "";
    }

    set password(value: string) {
        this.setStringPref("login.appPassword", value);
    }

    get username(): string {
        return this.getStringPref("login.username") ?? "username";
    }

    set username(value: string) {
        this.setStringPref("login.username", value);
    }

    get hostname(): string {
        return this.getStringPref("login.server") ?? "nextcloud.org";
    }

    set hostname(value: string) {
        this.setStringPref("login.server", value);
    }

    private getStringPref(key: string): string | null {
        let value = this.pref.getSync(key, "");
        if (value === null) {
            Logger.Info(TAG, "No value stored for " + key);
            return null;
        }

        if (value === "") {
            Logger.Info(TAG, "No value stored for " + key);
            return null;
        }

        return value as string;
    }

    private setStringPref(key: string, value: string | null) {
        Logger.Info(TAG, "Storing value for " + key);
        this.pref.putSync(key, value);
        this.pref.flush();
    }
}


export namespace NCommon {
    /**
     * Preferences for Nextcloud
     */
    export let Preference: NPreference;


    export function USER_AGENT() {
        return USER_AGENT_PART + deviceInfo.marketName + " (" + deviceInfo.productModel + ")";
    }

    /**
     * Initialise the common module
     * @param context The context to use for preferences
     */
    export function Initialise(context: common.UIAbilityContext) {
        Logger.Info(TAG, "Common initialised with User-Agent: " + USER_AGENT());
        Preference = new NPreference(context);
    }


    export function MakePreviewUrl(fileId: string, x: number = 64, y: number = 64): string {
        return `https://${NCommon.Preference.username}:${NCommon.Preference.password}@${NCommon.Preference.hostname}`
            + `/core/preview?fileId=${fileId}&x=${x}&y=${y}&mimeFallback=true`;
    }

    export function MakeDownloadUrl(filePath: string): string {
        let encodedPath = encodeURI(filePath);
        return `https://${NCommon.Preference.username}:${NCommon.Preference.password}@${NCommon.Preference.hostname}`
            + `/remote.php/dav/files/${NCommon.Preference.username}/${encodedPath}`;
    }

    let Base64Util = new util.Base64Helper();
    let Utf8Encoder = util.TextEncoder.create('utf-8');

    function Base64Encode(msg: string): string {
        return Base64Util.encodeToStringSync(Utf8Encoder.encodeInto(msg));
    }

    export function MakeAuthorization() {
        return 'basic ' + Base64Encode(NCommon.Preference.username + ":" + NCommon.Preference.password);
    }
}
