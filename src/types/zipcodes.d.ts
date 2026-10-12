declare module "zipcodes" {
  interface ZipInfo {
    zip: string;
    latitude: number;
    longitude: number;
    city: string;
    state: string;
    country: string;
  }
  const zipcodes: {
    codes: Record<string, ZipInfo>;
    lookup(zip: string | number): ZipInfo | undefined;
    lookupByCoords(lat: number, lng: number): ZipInfo | null;
    radius(zip: string | number, miles: number): string[];
    distance(a: string | number, b: string | number): number;
  };
  export default zipcodes;
}
