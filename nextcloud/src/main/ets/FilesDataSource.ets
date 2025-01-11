import { DirectoryEntry } from './webdav/DirEntryParserStateMachine';

class BasicDataSource<T> implements IDataSource {
    protected entries: T[] = [];
    private listeners: DataChangeListener[] = [];

    public totalCount(): number {
        return this.entries.length;
    }

    public getData(index: number): T {
        return this.entries[index];
    }

    registerDataChangeListener(listener: DataChangeListener): void {
        if (this.listeners.indexOf(listener) < 0) {
            console.info('add listener');
            this.listeners.push(listener);
        }
    }

    unregisterDataChangeListener(listener: DataChangeListener): void {
        const pos = this.listeners.indexOf(listener);
        if (pos >= 0) {
            console.info('remove listener');
            this.listeners.splice(pos, 1);
        }
    }

    notifyDataReload(): void {
        this.listeners.forEach(listener => {
            listener.onDataReloaded();
        })
    }

    notifyDataAdd(index: number): void {
        this.listeners.forEach(listener => {
            listener.onDataAdd(index);
        })
    }

    notifyDataChange(index: number): void {
        this.listeners.forEach(listener => {
            listener.onDataChange(index);
        })
    }

    notifyDataDelete(index: number): void {
        this.listeners.forEach(listener => {
            listener.onDataDelete(index);
        })
    }

    notifyDataMove(from: number, to: number): void {
        this.listeners.forEach(listener => {
            listener.onDataMove(from, to);
        })
    }

    notifyDatasetChange(operations: DataOperation[]): void {
        this.listeners.forEach(listener => {
            listener.onDatasetChange(operations);
        })
    }
}

export class FilesDataSource extends BasicDataSource<DirectoryEntry> {
    constructor() {
        super();
    }

    //
    // setFiles(entries: DirectoryEntry[]): void {
    //     let oldEntriesCount = this.entries.length;
    //     this.entries = entries;
    //
    //     for (let i = oldEntriesCount; i < entries.length; i++) {
    //         this.notifyDataAdd(i);
    //     }
    //     for (let i = entries.length; i < oldEntriesCount; i++) {
    //         this.notifyDataDelete(i);
    //     }
    //     for (let i = 0; i < oldEntriesCount; i++) {
    //         this.notifyDataChange(i);
    //     }
    // }

    public pushData(data: DirectoryEntry): void {
        this.entries.push(data);
        this.notifyDataAdd(this.entries.length - 1);
    }

    public deleteData(index: number): void {
        this.entries.splice(index, 1);
        this.notifyDataDelete(index);
    }

    public eraseData(): void {
        while (this.entries.length > 0) {
            this.deleteData(0);
        }
    }

    public reloadData(): void {
        this.notifyDataReload();
    }
}
