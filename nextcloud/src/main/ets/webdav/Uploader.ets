import { rcp } from "@kit.RemoteCommunicationKit";
import { NCommon } from "../Common";
import fs from "@ohos.file.fs"
import { Logger } from "../Logger";

const TAG = "Nextcloud-Upload";

let session: rcp.Session | null = null;

export async function CreatePath(path: string): Promise<number> {
    let sessionConfiguration: rcp.SessionConfiguration = {
        headers: {
            'authorization': NCommon.MakeAuthorization(),
            'user-agent': NCommon.USER_AGENT(),
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
    };

    if (!session) {
        session = rcp.createSession(sessionConfiguration);
    }


    try {
        let fullPath = "https://" + NCommon.Preference.hostname + "/remote.php/dav/files/" + NCommon.Preference.username + "/" + path + "/";
        let resp = await session.fetch(new rcp.Request(fullPath, "MKCOL", {}));
        Logger.Info(TAG, "Create path response: " + resp.statusCode);
        if (resp.statusCode !== 201) {
            Logger.Error(TAG, "Failed to create path: " + resp.statusCode);
        }
        return resp.statusCode;
    } catch (e) {
        Logger.Error(TAG, "Failed to create path: " + e);
    }

    return -1;
}

export async function UploadFile(filename: string, path: string, fd: number): Promise<number> {
    let sessionConfiguration: rcp.SessionConfiguration = {
        headers: {
            'authorization': NCommon.MakeAuthorization(),
            'user-agent': NCommon.USER_AGENT(),
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
    };

    if (!session) {
        session = rcp.createSession(sessionConfiguration);
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
