import { dataSharePredicates } from '@kit.ArkData';
import { BasicDataSource } from 'nextcloud';
import { photoAccessHelper as PHelper } from '@kit.MediaLibraryKit';
import { Logger } from '../utils/Logger';

const TAG = 'MediaListDataSource';

export enum UploadStatus {
    None,
    Uploading,
    Uploaded,
    Failed,
    Existed,
}

@Observed
export class PhotoItem {
    asset: PHelper.PhotoAsset;
    uploadStatus: UploadStatus = UploadStatus.None;

    constructor(asset: PHelper.PhotoAsset) {
        this.asset = asset;
    }

    get displayName(): string {
        return this.asset.displayName ?? '';
    }

    get uri(): string {
        Logger.Info(TAG, `PhotoItem.uri: ${this.asset}`);
        Logger.Info(TAG, `PhotoItem.uri: ${this.asset.uri}`);
        return this.asset.uri ?? '';
    }

    get dateTaken(): Date {
        return new Date(this.asset.get(PHelper.PhotoKeys.DATE_TAKEN_MS) as number);
    }

    get dateTakenMs(): number {
        return this.asset.get(PHelper.PhotoKeys.DATE_TAKEN_MS) as number;
    }

    get size(): number {
        return this.asset.get(PHelper.PhotoKeys.SIZE) as number ?? 0;
    }

    get photoType(): PHelper.PhotoType {
        return this.asset.get(PHelper.PhotoKeys.PHOTO_TYPE) as PHelper.PhotoType;
    }

    get coverPosition(): number {
        return this.asset.get(PHelper.PhotoKeys.COVER_POSITION) as number;
    }

    get isVideo(): boolean {
        return this.photoType === PHelper.PhotoType.VIDEO;
    }

    getReadOnlyFd(): Promise<number> {
        return this.asset.getReadOnlyFd();
    }

    close(fd: number): Promise<void> {
        return this.asset.close(fd);
    }
}

let FETCH_OPTIONS: PHelper.FetchOptions = {
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
    ],
    predicates: new dataSharePredicates.DataSharePredicates().orderByDesc(PHelper.PhotoKeys.DATE_TAKEN),
};

export class ImageListDataSource extends BasicDataSource<PhotoItem> {
    constructor(patterns: string[]) {
        super();
        let asyncLoad = async () => {
            let helper = PHelper.getPhotoAccessHelper(getContext(this));
            let assets = await helper.getAssets(FETCH_OPTIONS);
            for (let asset of await assets.getAllObjects()) {
                for (let pattern of patterns) {
                    if (asset.displayName.match(pattern)) {
                        this.addAsset(asset);
                    }
                }
            }
        };

        asyncLoad();
    }

    private addAsset(asset: PHelper.PhotoAsset) {
        this.entries.push(new PhotoItem(asset));
        this.notifyDataAdd(this.entries.length - 1);
    }
}
