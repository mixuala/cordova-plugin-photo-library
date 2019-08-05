export declare module PhotoLibraryCordova {

  export interface Plugin {

    getLibrary(success: (chunk: { library: LibraryItem[], isLastChunk: boolean }) => void, error: (err: any) => void, options?: GetLibraryOptions): void;

    requestAuthorization(success: () => void, error: (err: any) => void, options?: RequestAuthorizationOptions): void;

    getAlbums(success: (result: AlbumItem[]) => void, error: (err:any) => void): void;
    getMoments(success: (result: AlbumItem[]) => void, error: (err:any) => void, options?:GetMomentsOptions): void;
    isAuthorized(success: (result: boolean) => void, error: (err:any) => void): void;

    getThumbnailURL(photoId: string, success: (result: string) => void, error: (err: any) => void, options?: GetThumbnailOptions): void;
    getThumbnailURL(libraryItem: LibraryItem, success: (result: string) => void, error: (err: any) => void, options?: GetThumbnailOptions): void;
    getThumbnailURL(photoId: string, options?: GetThumbnailOptions): string; // Will not work in browser
    getThumbnailURL(libraryItem: LibraryItem, options?: GetThumbnailOptions): string; // Will not work in browser

    getPhotoURL(photoId: string, success: (result: string) => void, error: (err: any) => void, options?: GetPhotoOptions): void;
    getPhotoURL(libraryItem: LibraryItem, success: (result: string) => void, error: (err: any) => void, options?: GetPhotoOptions): void;
    getPhotoURL(photoId: string, options?: GetPhotoOptions): string; // Will not work in browser
    getPhotoURL(libraryItem: LibraryItem, options?: GetPhotoOptions): string; // Will not work in browser

    getThumbnail(photoId: string, success: (data: Blob|string, mimeType?:string) => void, error: (err: any) => void, options?: GetThumbnailOptions): void;
    getThumbnail(libraryItem: LibraryItem, success: (data: Blob|string, mimeType?:string) => void, error: (err: any) => void, options?: GetThumbnailOptions): void;

    getPhoto(photoId: string, success: (result: Blob) => void, error: (err: any) => void, options?: GetPhotoOptions): void;
    getPhoto(libraryItem: LibraryItem, success: (result: Blob) => void, error: (err: any) => void, options?: GetPhotoOptions): void;

    getLibraryItem(libraryItem: LibraryItem, success: (result: Blob) => void, error: (err: any) => void, options?: GetPhotoOptions): void;

    stopCaching(success: () => void, error: (err: any) => void): void;

    saveImage(url: string, album: AlbumItem | string, success: (libraryItem: LibraryItem) => void, error: (err: any) => void, options?: GetThumbnailOptions): void;

    saveVideo(url: string, album: AlbumItem | string, success: () => void, error: (err: any) => void): void;

  }

  export interface LibraryItem {
    id: string;
    photoURL: string;
    thumbnailURL: string;
    fileName: string;
    width: number;
    height: number;
    creationDate: Date;
    latitude?: number;
    longitude?: number;
    albumIds?: string[];
  }

  export interface ExifLibraryItem extends LibraryItem {
    orientation?: number;
    '{Exif}'?:{
      DateTimeOriginal:string,
      PixelXDimension:number,
      PixelYDimension:number,
    },
    '{GPS}'?:{
      Altitude: number,
      Latitude: number,
      Longitude: number,
      Speed: number,
    },
    '{TIFF}'?:{
      Artist:string,
      Copyright:string,
      Orientation:number,
    },
    isFavorite?: boolean;
  }

  export interface IosLibraryItem extends ExifLibraryItem {
    speed?: number;
    burstIdentifier?: string;
    representsBurst?: boolean;
    duration?: number;
  }

  export interface AlbumItem {
    id: string;
    title: string;
    // extras
    location?: string;
    startDate?: Date;
    endDate?: Date;
    itemIds: string[];
  }

  export interface GetLibraryOptions {
    thumbnailWidth?: number;
    thumbnailHeight?: number;
    quality?: number;
    itemsInChunk?: number;
    chunkTimeSec?: number;
    useOriginalFileNames?: boolean;
    includeImages?: boolean;
    includeAlbumData?: boolean;
    includeCloudData?: boolean;
    includeVideos?: boolean;
    maxItems?: number;
  }

  export interface GetMomentsOptions {
    // date string, e.g. "2108-01-01"
    from: string;
    to: string
  }

  export interface RequestAuthorizationOptions {
    read?: boolean;
    write?: boolean;
  }

  export interface GetThumbnailOptions {
    thumbnailWidth?: number;
    thumbnailHeight?: number;
    quality?: number;
    dataURL?: boolean;
  }

  export interface GetPhotoOptions {
    quality?: number;
    dataURL?: boolean;
    mimeType?: string;
  }

}

interface CordovaPlugins {
  photoLibrary: PhotoLibraryCordova.Plugin;
}
