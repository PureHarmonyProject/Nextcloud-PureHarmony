import { Logger, NCommon } from 'nextcloud';
import { PermissionManager } from '../utils/PermissionManager';
import { AddAssetResult, Category } from '../models/Category';
import { LengthMetrics } from '@kit.ArkUI';
import { photoAccessHelper as PHelper } from '@kit.MediaLibraryKit';
import { dataSharePredicates } from '@kit.ArkData';
import { PhotoItem, UploadStatus } from '../models/PhotoItem';

const TAG = "Page-UploadPage"


const FETCH_OPTIONS: PHelper.FetchOptions = {
    fetchColumns: [
        PHelper.PhotoKeys.URI,
        PHelper.PhotoKeys.PHOTO_TYPE,
        PHelper.PhotoKeys.PHOTO_SUBTYPE,
        PHelper.PhotoKeys.DISPLAY_NAME,
        PHelper.PhotoKeys.DATE_TAKEN,
        PHelper.PhotoKeys.DATE_ADDED_MS,
        PHelper.PhotoKeys.SIZE,
        PHelper.PhotoKeys.WIDTH,
        PHelper.PhotoKeys.HEIGHT,
        PHelper.PhotoKeys.TITLE,
        PHelper.PhotoKeys.COVER_POSITION,
        PHelper.PhotoKeys.DYNAMIC_RANGE_TYPE,
        PHelper.PhotoKeys.DETAIL_TIME,
        PHelper.PhotoKeys.DATE_TAKEN_MS,
    ],
    predicates: new dataSharePredicates.DataSharePredicates().orderByDesc(PHelper.PhotoKeys.DATE_TAKEN),
};


@Component
struct PhotoView {
    @ObjectLink asset: PhotoItem;
    @Prop category: Category;
    @State private thumbnail: PixelMap | null = null;

    build() {
        Stack() {
            Image(this.thumbnail)
                .height(100)
                .width(100)
                .objectFit(ImageFit.Cover)

            Text(this.asset.isVideo ? '▶' : '')
                .fontSize(48)
                .fontFamily('monospace')
                .fontColor(Color.Red)
        }
        .draggable(false)
        .height(100)
        .width(100)
        .borderWidth(3)
        .borderColor(
            (this.asset.uploadStatus == UploadStatus.Uploaded) ? Color.Green :
                (this.asset.uploadStatus == UploadStatus.Uploading) ? Color.Yellow :
                    (this.asset.uploadStatus == UploadStatus.Failed) ? Color.Red :
                        (this.asset.uploadStatus == UploadStatus.None) ? Color.Gray :
                            (this.asset.uploadStatus == UploadStatus.Existed) ? Color.Blue : Color.Gray)
        .onClick(async () => {
            await this.asset.upload(NCommon.Preference.baseUploadDirectory + this.category.location);
        })
        .onAppear(async () => {
            if (this.thumbnail === null) {
                this.thumbnail = await this.asset.getThumbnail({ height: 150, width: 150 });
            }
        })
    }
}

@Component
struct PhotosGridView {
    @ObjectLink category: Category;
    private scroller: Scroller = new Scroller();

    build() {
        Stack() {
            Grid(this.scroller) {
                LazyForEach(this.category.visibleItems, (asset: PhotoItem, index: number) => {
                    GridItem() {
                        PhotoView({ asset: asset, category: this.category })
                    }
                    .width('100%')
                    .onAppear(() => {
                        if (index == this.category.visibleItems.totalCount() - 1) {
                            this.category.showNext50();
                        }
                    })
                })
            }
            .fadingEdge(true, { fadingEdgeLength: LengthMetrics.vp(80) })
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .scrollBar(BarState.On)
            .edgeEffect(EdgeEffect.Spring)
            .columnsGap(8)
            .rowsGap(8)
            .cachedCount(10)
            .width('100%')
            .height('auto')

            Column() {
                Button($r('app.string.upload_all'))
                    .onClick(() => {
                        Logger.Info(TAG, `Upload all in '${this.category.name}'`);
                        this.category.uploadAllAssets();
                    })
                    .width('30%')
            }
            .width('100%')
            .position({ bottom: 5 })
        }
    }
}


@Preview
@Component
export struct UploadPage {
    @State private categories: Category[] = [];

    async aboutToAppear() {
        let context = this.getUIContext().getHostContext()!;
        let result1 = await PermissionManager.RequestPermission(context, 'ohos.permission.READ_IMAGEVIDEO');
        Logger.Info(TAG, `Request permission result: ${result1}`);
        let result2 = await PermissionManager.RequestPermission(context, 'ohos.permission.MEDIA_LOCATION');
        Logger.Info(TAG, `Request permission result: ${result2}`);

        this.initializeCategoriesAndAssets(context);
    }

    build() {
        Tabs() {
            ForEach(this.categories, (category: Category) => {
                TabContent() {
                    Flex({ direction: FlexDirection.Column, space: { main: LengthMetrics.px(20) } }) {
                        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Baseline }) {
                            Text(category.name)
                                .fontWeight(FontWeight.Bold)
                                .fontSize(24)

                            Text(category.location)
                        }
                        .height('32')

                        ForEach(category.patterns, (pattern: string) => {
                            Text(pattern)
                                .fontSize(12)
                                .fontColor(Color.Green)
                                .fontFamily('serif')
                        })

                        PhotosGridView({ category: category })
                    }
                    .width('100%')
                    .height('100%')
                }
                .margin(10)
                .tabBar(category.name)
            })
        }
    }

    private async initializeCategoriesAndAssets(context: Context) {
        while (this.categories.length > 0) {
            this.categories.pop();
        }
        for (let c of NCommon.Preference.categories) {
            this.categories.push(new Category(c));
        }

        let helper = PHelper.getPhotoAccessHelper(context);
        let result = await helper.getAssets(FETCH_OPTIONS);
        for (let asset of await result.getAllObjects()) {
            let photoItem = new PhotoItem(asset);
            for (let category of this.categories) {
                if (category.tryAddAsset(photoItem) != AddAssetResult.Unmatched) {
                    break;
                }
            }
        }
        result.close();
    }
}
