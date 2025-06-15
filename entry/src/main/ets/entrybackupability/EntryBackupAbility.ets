import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackupExtensionAbility, BundleVersion, fileIo } from '@kit.CoreFileKit';
import { NCommon } from 'nextcloud';

interface BackupContentV1 {
    server: string;
    username: string;
    appPassword: string;
}

interface BackupObject {
    version: number;
    settings: BackupContentV1;
}

export default class EntryBackupAbility extends BackupExtensionAbility {
    async onBackup() {
        let object: BackupObject = {
            version: 1,
            settings: {
                server: NCommon.Preference.hostname,
                username: NCommon.Preference.username,
                appPassword: NCommon.Preference.password
            }
        };
        let jsonString = JSON.stringify(object);

        // write to file
        let filePath = this.context.backupDir + '/nextcloud_backup.json';
        let file = fileIo.createWriteStream(filePath);
        file.write(jsonString);
        file.close();

        hilog.info(0x0000, 'testTag', `onBackup ok, filePath: %{public}s`, filePath);
    }

    async onRestore(bundleVersion: BundleVersion) {
        hilog.info(0x0000, 'testTag', 'onRestore ok %{public}s', JSON.stringify(bundleVersion));

        // read from file
        let filePath = this.context.backupDir + '/nextcloud_backup.json';
        let file = fileIo.createReadStream(filePath);
        let data = file.read();
        if (!data) {
            hilog.error(0x0000, 'testTag', 'onRestore failed, no data found in file: %{public}s', filePath);
            return;
        }

        let object: BackupObject = JSON.parse(data);
        NCommon.Preference.hostname = object.settings.server;
        NCommon.Preference.username = object.settings.username;
        NCommon.Preference.password = object.settings.appPassword;
        hilog.info(0x0000, 'testTag', 'onRestore completed with data: %{public}s', JSON.stringify(object));

        file.close();
    }
}
