import { rcp } from '@kit.RemoteCommunicationKit';
import { NCommon } from '../Common';
import fs from '@ohos.file.fs';
import { Logger } from '../Logger';

const TAG = "Nextcloud-Upload";


let __session: rcp.Session | null = null;

function EnsureSession(): rcp.Session {
    let sessionConfiguration: rcp.SessionConfiguration = {
        headers: {
            'authorization': NCommon.MakeAuthorization(),
            'user-agent': NCommon.UserAgent(),
            'accept': 'text/plains'
        },
        requestConfiguration: {
            tracing: {
                httpEventsHandler: {
                    onUploadProgress: (progress: number) => {
                        Logger.Info(TAG, "Upload progress: " + progress);
                    },
                }
            }
        }
    }
    if (!__session) {
        __session = rcp.createSession(sessionConfiguration);
    }
    return __session;
}

export async function Exists(path: string, filename: string = ""): Promise<boolean> {
    let session = EnsureSession();
    let fullPath = "https://" + NCommon.Preference.hostname + "/remote.php/dav/files/" + NCommon.Preference.username + "/" + path + "/" + filename;
    Logger.Info(TAG, "Checking if path exists: " + fullPath);

    try {
        let resp = await session.fetch(new rcp.Request(fullPath, "HEAD", {}));
        if (resp.statusCode === 200 || resp.statusCode === 207) {
            Logger.Info(TAG, "Path exists: " + fullPath);
            return true;
        } else if (resp.statusCode === 404) {
            Logger.Info(TAG, "Path does not exist: " + fullPath);
            return false;
        } else {
            Logger.Error(TAG, "Failed to check path existence: " + resp.statusCode);
            return false;
        }
    } catch (e) {
        Logger.Error(TAG, "Error checking path existence: " + e);
        return false;
    }
}

export async function CreatePath(path: string): Promise<number> {
    let session = EnsureSession();
    if (await Exists(path)) {
        Logger.Info(TAG, "Path already exists: " + path);
        return 201;
    }

    let segment = path.split("/");
    let respCode = -1;
    for (let i = 0; i < segment.length; i++) {
        let thisLevel = segment.slice(0, i + 1).join("/");
        if (!thisLevel) {
            continue;
        }
        let fullPath = "https://" + NCommon.Preference.hostname + "/remote.php/dav/files/" + NCommon.Preference.username + "/" + thisLevel + "/";
        try {
            let resp = await session.fetch(new rcp.Request(fullPath, "MKCOL", {}));
            Logger.Info(TAG, `Create path '${thisLevel}', response: ${resp.statusCode}`);
            respCode = resp.statusCode;
            if (resp.statusCode !== 201 && resp.statusCode !== 405) {
                Logger.Error(TAG, "Failed to create path: " + resp.statusCode);
                return resp.statusCode;
            }
        } catch (e) {
            Logger.Error(TAG, "Failed to create path: " + e);
            return respCode;
        }
    }
    return respCode;
}

export async function UploadFile(filename: string, path: string, fd: number): Promise<number> {
    let session = EnsureSession();
    if (await Exists(path, filename)) {
        Logger.Info(TAG, "File already exists: " + filename);
        return 204; // No Content, file already exists
    }

    let stream = await fs.fdopenStream(fd, "r");
    Logger.Info(TAG, "File stream opened");

    let fullpath = "https://" + NCommon.Preference.hostname + "/remote.php/dav/files/" + NCommon.Preference.username + "/" + path + "/" + filename;
    Logger.Info(TAG, "Uploading file to " + fullpath);

    try {
        let resp = await session.put(fullpath, new rcp.UploadFromStream(stream));
        Logger.Info(TAG, "Upload response: " + resp.statusCode);
        if (resp.statusCode !== 201) {
            Logger.Error(TAG, "Failed to upload file: " + resp.statusCode);
        }
        return resp.statusCode;
    } catch (e) {
        Logger.Error(TAG, "Failed to upload file: " + e);
    }

    return -1;
}
