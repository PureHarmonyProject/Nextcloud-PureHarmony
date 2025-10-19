import { BasicDataSource } from 'nextcloud';
import { PhotoItem } from './PhotoItem';


export class ImageListDataSource extends BasicDataSource<PhotoItem> {
    constructor() {
        super();
    }

    public addAsset(asset: PhotoItem) {
        this.entries.push(asset);
        this.notifyDataAdd(this.entries.length - 1);
    }

    public addWithoutNotify(asset: PhotoItem) {
        this.entries.push(asset);
    }
}
