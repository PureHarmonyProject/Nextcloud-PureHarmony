import { NCommon } from "nextcloud";

export function MakePreviewUrl(fileId: string, x: number = 64, y: number = 64): string {
    return `https://${NCommon.Preference.username}:${NCommon.Preference.password}@${NCommon.Preference.hostname}`
        + `/core/preview?fileId=${fileId}&x=${x}&y=${y}&mimeFallback=true`;
}

export function MakeDownloadUrl(filePath: string): string {
    let encodedPath = encodeURI(filePath);
    return `https://${NCommon.Preference.username}:${NCommon.Preference.password}@${NCommon.Preference.hostname}`
        + `/remote.php/dav/files/${NCommon.Preference.username}/${encodedPath}`;
}
