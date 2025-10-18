import { deviceInfo } from '@kit.BasicServicesKit';
import { preferences, ValueType } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from './Logger';
import util from '@ohos.util';


const TAG = "Nextcloud-Common";

const USER_AGENT_PART = "Nextcloud Client for HarmonyOS on ";

const LOGIN_APP_PASSWORD = "login.appPassword";
const LOGIN_USERNAME = "login.username";
const LOGIN_SERVER = "login.server";
const UPLOAD_REPLACE_EXISTING = "upload.replaceExisting";

class NPreference {
    static SETTINGS_KEYS: string[] = [
        LOGIN_APP_PASSWORD,
        LOGIN_USERNAME,
        LOGIN_SERVER,
        UPLOAD_REPLACE_EXISTING,
    ];
    private pref: preferences.Preferences;

    constructor(context: common.UIAbilityContext) {
        this.pref = preferences.getPreferencesSync(context, { name: "nextcloud" });
    }

    get password(): string {
        return this.getPref(LOGIN_APP_PASSWORD, "");
    }

    set password(value: string) {
        this.setPref(LOGIN_APP_PASSWORD, value);
    }

    get username(): string {
        return this.getPref(LOGIN_USERNAME, "username");
    }

    set username(value: string) {
        this.setPref(LOGIN_USERNAME, value);
    }

    get hostname(): string {
        return this.getPref(LOGIN_SERVER, "nextcloud.com");
    }

    set hostname(value: string) {
        this.setPref(LOGIN_SERVER, value);
    }

    get replaceExistingFiles(): boolean {
        return this.getPref(UPLOAD_REPLACE_EXISTING, false);
    }

    set replaceExistingFiles(doReplace: boolean) {
        this.setPref(UPLOAD_REPLACE_EXISTING, doReplace);
    }

    public hasLogon() {
        return this.password !== '' && this.username !== '';
    }

    private getPref<T>(key: string, defaultValue: T): T {
        if (!NPreference.SETTINGS_KEYS.includes(key)) {
            Logger.Error(TAG, "Invalid preference key: " + key);
            return defaultValue;
        }

        try {
            let value = this.pref.getSync(key, "") as T;
            if (value === null) {
                Logger.Info(TAG, "No value stored for " + key);
                return defaultValue;
            }

            return value as T;
        } catch (error) {
            Logger.Info(TAG, "No value stored for " + key);
            return defaultValue;
        }

    }

    private setPref(key: string, value: ValueType) {
        if (!NPreference.SETTINGS_KEYS.includes(key)) {
            Logger.Error(TAG, "Invalid preference key: " + key);
            return;
        }

        Logger.Info(TAG, "Storing value for " + key);
        try {
            this.pref.putSync(key, value);
            this.pref.flushSync();
        } catch (error) {
            Logger.Error(TAG, `failed to put and flush preferences: ${JSON.stringify(error)}`);
        }
    }
}


export namespace NCommon {
    /**
     * Preferences for Nextcloud
     */
    export let Preference: NPreference;

    export function UserAgent() {
        return USER_AGENT_PART + deviceInfo.marketName + " (" + deviceInfo.productModel + ")";
    }

    /**
     * Initialise the common module
     * @param context The context to use for preferences
     */
    export function Initialise(context: common.UIAbilityContext) {
        Logger.Info(TAG, "Common initialised with User-Agent: " + UserAgent());
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

    export function MakeAuthorization(): string {
        return 'basic ' + Base64Encode(NCommon.Preference.username + ":" + NCommon.Preference.password);
    }
}
