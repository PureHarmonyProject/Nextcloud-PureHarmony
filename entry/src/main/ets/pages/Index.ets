import { Logger, NCommon } from 'nextcloud';
import { App, promptAction } from '@kit.ArkUI';
import { Path } from '../utils/Path';
import { FolderPageBuilder } from './FolderPage';
import { UploadPage } from './UploadPage';
import { LoginPage } from './LoginPage';
import { SettingsPage } from './SettingsPage';

const TAG = "Page-Index";

const EXIT_TOAST_DURATION: number = 2000;

@Entry
@Component
struct Index {
    @State currentIndex: number = 0;
    @Provide('FolderList.Lanes') listLanes: number = 2;
    @Provide('FolderList.PathStack') pathStack: NavPathStack = new NavPathStack();
    @State private loginPageDialogId: number = 0;
    private backedOnce: boolean = false;

    onBackPress(): boolean {
        Logger.Info(TAG, `onBackPressed on tab ${this.currentIndex}`);
        if (this.currentIndex !== 0) {
            return false; // not on files tab, let system handle it
        }

        if (this.pathStack.size() > 0) {
            return true; // go back to parent level
        }

        if (this.backedOnce) {
            return false; // exit directly
        } else {
            this.backedOnce = true;
            setTimeout(() => {
                this.backedOnce = false;
            }, EXIT_TOAST_DURATION);

            try {
                this.getUIContext().getPromptAction().showToast({
                    message: "Press again to exit",
                    duration: EXIT_TOAST_DURATION,
                });
            } catch (error) {
                Logger.Error(TAG, `Failed to show toast?`);
            }
            return true;
        }
    }

    aboutToAppear(): void {
        Logger.Info(TAG, `aboutToAppear`);
    }

    async doLogin() {
        try {
            let context = this.getUIContext();
            let options: promptAction.CustomDialogOptions = {
                builder: () => {
                    this.LoginPageDialog()
                },
                isModal: true,
                autoCancel: false,
            };
            this.loginPageDialogId = await context.getPromptAction().openCustomDialog(options);
            Logger.Info(TAG, `done`);
        } catch (error) {
            Logger.Error(TAG, `${JSON.stringify(error)}`);
        }
    }

    onPageShow() {
        App.setImageCacheCount(500);
        App.setImageRawDataCacheSize(1024 * 1024 * 100); // 100MB
        App.setImageFileCacheSize(1024 * 1024 * 500); // 100MB

        if (!NCommon.Preference.hasLogon()) {
            this.doLogin();
        }
    }

    build() {
        Tabs({ barPosition: BarPosition.End }) {
            TabContent() {
                Flex({ direction: FlexDirection.Column }) {
                    Navigation(this.pathStack) {
                        FolderPageBuilder("", new Path())
                    }
                    .navBarWidth(0)
                    .mode(NavigationMode.Stack)

                    Row({ space: 10 }) {
                        Button("Lanes: " + this.listLanes)
                            .onClick(() => {
                                this.listLanes = (this.listLanes % 3) + 1;
                            })
                            .width(100)
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center)
                    .justifyContent(FlexAlign.Center)
                    .height(60)
                    .margin({ top: 10, bottom: 10 })

                }
            }
            .tabBar($r("app.string.tab_files"))

            TabContent() {
                UploadPage()
                    .width('100%')
                    .height('100%')
            }
            .tabBar($r('app.string.tab_upload'))

            TabContent() {
                SettingsPage()
                    .width('100%')
                    .height('100%')
            }
            .tabBar($r('app.string.tab_settings'))
        }
        .onChange((index: number) => {
            this.currentIndex = index;
        })
        .width('100%')
        .height('100%')
        .scrollable(false)
    }

    @Builder
    private LoginPageDialog() {
        LoginPage({ dialogId: this.loginPageDialogId })
    }
}
