import { Logger, NCommon } from 'nextcloud';

const TAG = 'pages/Settings';

@Entry
@Component
export struct SettingsPage {
    scroller: Scroller = new Scroller();
    @State private username: string = "<username>";
    @State private hostname: string = "<hostname>";
    @State private uploadReplaceExisting: boolean = false;

    aboutToAppear(): void {
        this.doLoadSettings();
    }

    build() {
        Column() {
            Text($r('app.string.tab_settings'))
                .fontSize($r('sys.float.titlebar_main_title_text_font_size'))
                .fontWeight(FontWeight.Bold)
                .fontSize(24)
                .padding(16)
                .width('100%')

            Scroll(this.scroller) {
                Flex({ direction: FlexDirection.Column }) {
                    Column({ space: 4 }) {
                        Text($r('app.string.login_info'))
                            .width('100%')
                            .fontSize($r('sys.float.subheader_title_font_size'))
                            .fontWeight(FontWeight.Bold)

                        Row() {
                            Text($r('app.string.username'))
                            Text(this.username)
                                .copyOption(CopyOptions.LocalDevice)
                        }
                        .justifyContent(FlexAlign.SpaceBetween)
                        .width('100%')
                        .height(24)

                        Row() {
                            Text($r('app.string.hostname'))
                            Text(this.hostname)
                                .copyOption(CopyOptions.LocalDevice)
                        }
                        .justifyContent(FlexAlign.SpaceBetween)
                        .width('100%')
                        .height(24)
                    }

                    Divider()
                        .margin({ top: 16, bottom: 16 })

                    Column({ space: 4 }) {
                        Text($r('app.string.upload'))
                            .width('100%')
                            .fontWeight(FontWeight.Bold)
                            .fontSize($r('sys.float.subheader_title_font_size'))

                        Row() {
                            Text('Base Directory')
                            Text('/InstantUpload')
                                .copyOption(CopyOptions.LocalDevice)
                        }
                        .justifyContent(FlexAlign.SpaceBetween)
                        .width('100%')
                        .height(24)

                        Row() {
                            Text($r('app.string.replace_existing_files'))
                            Row({ space: 8 }) {
                                Text(this.uploadReplaceExisting ? $r('app.string.yes') : $r('app.string.no'))
                                Toggle({ type: ToggleType.Switch, isOn: this.uploadReplaceExisting })
                                    .onChange((value: boolean) => {
                                        this.uploadReplaceExisting = value;
                                    })
                                    .height('60px')
                                    .width('107px')
                            }
                            .alignItems(VerticalAlign.Center)
                        }
                        .justifyContent(FlexAlign.SpaceBetween)
                        .width('100%')
                        .height(24)
                    }
                }
                .margin({ left: 24, right: 24 })
            }
            .align(Alignment.TopStart)
            .edgeEffect(EdgeEffect.Spring)
            .flexGrow(1)

            Button('Save Settings', { stateEffect: true })
                .onClick(() => {
                    this.doSaveSettings();
                    this.getUIContext().getPromptAction().showToast({
                        message: 'settings saved'
                    });
                })
                .margin({ top: 16, bottom: 16 })
        }
        .height('100%')
    }

    private doLoadSettings() {
        if (NCommon.Preference) {
            this.username = NCommon.Preference.username;
            this.hostname = NCommon.Preference.hostname;
            this.uploadReplaceExisting = NCommon.Preference.replaceExistingFiles;
        } else {
            Logger.Error(TAG, `failed to load settings, preference is undefined`);
        }
    }

    private doSaveSettings() {
        if (NCommon.Preference) {
            NCommon.Preference.username = this.username;
            NCommon.Preference.hostname = this.hostname;
            NCommon.Preference.replaceExistingFiles = this.uploadReplaceExisting;
        } else {
            Logger.Error(TAG, `failed to save settings, preference is undefined`);
        }
    }
}
