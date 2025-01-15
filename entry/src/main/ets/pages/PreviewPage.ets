import { DirectoryEntry } from "nextcloud";
import { Logger } from "../utils/Logger";
import { Path } from "../utils/Path";
import { MakeDownloadUrl, MakePreviewUrl } from "../utils/Utils";

const TAG: string = "Page-PreviewPage";

export let PREVIEW_PAGE_NAME: string = "PreviewPage";

@Component
struct PreviewPage {
    @Prop entry: DirectoryEntry;
    @Prop fullPath: Path = new Path();
    @State private previewLoaded: boolean = false;
    @State private imageScale: number = 1;
    private previousScale: number = 1;
    @State private imageOffsetX: number = 0;
    @State private imageOffsetY: number = 0;
    private previousOffsetX: number = 0;
    private previousOffsetY: number = 0;
    @State private previewLink: string = MakePreviewUrl(this.entry.fileId, 100, 100);
    @State @Watch('onPreviewLevelChanged') private previewLevel: number = 0;
    @State private failedToLoad: boolean = false;
    @State private failedReason: string = "";
    @State private title: string = "";

    onPreviewLevelChanged() {
        Logger.Info(TAG, "Preview level: " + this.previewLevel);
        if (this.previewLevel == 4) {
            this.previewLoaded = true;
        }
    }

    aboutToAppear(): void {
        Logger.Info(TAG, "PreviewPage about to appear for file ID: " + this.entry.fileId);
        this.title = this.fullPath.parentName + "/" + this.entry.name;
    }

    build() {
        NavDestination() {
            Stack() {
                Image(this.previewLink)
                    .onComplete(() => {
                        this.previewLevel++;

                        if (this.previewLevel == 2) {
                            Logger.Info(TAG, "Preview image loaded, start loading full image");
                            if (this.entry.mime.startsWith("image/")) {
                                this.previewLink = MakeDownloadUrl(this.fullPath.path(false));
                            } else {
                                this.previewLink = MakePreviewUrl(this.entry.fileId, 1000, 1000);
                            }
                        }
                    })
                    .onError((e) => {
                        Logger.Error(TAG, "Failed to load preview image: " + e.message);
                        this.failedReason = e.message;
                        this.failedToLoad = true;
                    })
                    .draggable(this.previewLoaded)
                    .objectFit(ImageFit.Contain)
                    .scale({ x: this.imageScale, y: this.imageScale })
                    .offset({ x: this.imageOffsetX, y: this.imageOffsetY })
                    .dynamicRangeMode(DynamicRangeMode.HIGH)
                    .gesture(
                        GestureGroup(GestureMode.Parallel,
                            PanGesture()
                                .onActionStart((event: GestureEvent) => {
                                    this.previousOffsetX = this.imageOffsetX;
                                    this.previousOffsetY = this.imageOffsetY;
                                })
                                .onActionUpdate((event: GestureEvent) => {
                                    this.imageOffsetX = this.previousOffsetX + event.offsetX * this.imageScale;
                                    this.imageOffsetY = this.previousOffsetY + event.offsetY * this.imageScale;
                                })
                                .onActionEnd((event: GestureEvent) => {
                                    this.previousOffsetX = this.imageOffsetX;
                                    this.previousOffsetY = this.imageOffsetY;
                                }),
                            PinchGesture()
                                .onActionStart((event: GestureEvent) => {
                                    this.previousScale = this.imageScale;
                                })
                                .onActionUpdate((event: GestureEvent) => {
                                    this.imageScale = this.previousScale * event.scale;
                                })
                                .onActionEnd((event: GestureEvent) => {
                                    this.previousScale = this.imageScale;
                                }),
                        )
                    )
                    .width('100%')
                    .height('100%')

                LoadingProgress()
                    .layoutWeight(1)
                    .width('10%')
                    .enableLoading(!this.failedToLoad)
                    .visibility(this.previewLoaded ? Visibility.Hidden : Visibility.Visible)

                Text("Failed to load preview image\n" + this.failedReason)
                    .visibility(this.failedToLoad ? Visibility.Visible : Visibility.Hidden)
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .fontColor(Color.Gray)

            }
            .width('100%')
            .height('100%')
        }
        .title(this.title)
    }
}

export interface PreviewPageProps {
    entry: DirectoryEntry;
    fullPath: Path;
}

@Builder
export function PreviewPageBuilder(_name: string, props: PreviewPageProps) {
    PreviewPage(props);
}
