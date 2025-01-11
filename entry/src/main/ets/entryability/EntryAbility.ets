import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { NCommon } from 'nextcloud';
import { Logger } from '../common/Logger';

const TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
        this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
        Logger.Info(TAG, 'Ability onCreate');
        NCommon.Initialise(this.context);
    }

    onDestroy() {
        Logger.Info(TAG, 'Ability onDestroy');
    }

    async onWindowStageCreate(windowStage: window.WindowStage) {
        Logger.Info(TAG, 'Main window is created, set main page for this ability');

        try {
            await windowStage.loadContent('pages/Index');
            Logger.Info(TAG, 'Succeeded in loading the content.');
        } catch (e) {
            Logger.Error(TAG, 'Failed to load the content. Cause: ' + JSON.stringify(e) ?? '');
            return;
        }

        Logger.Info(TAG, 'Main window created.');
    }

    onWindowStageDestroy() {
        Logger.Info(TAG, 'Main window is destroyed, release UI related resources');
    }

    onForeground() {
        Logger.Info(TAG, 'Ability has brought to foreground');
    }

    onBackground() {
        Logger.Info(TAG, 'Ability has back to background');
    }
}
