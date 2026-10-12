// State metadata, safe to import from client components (no ZIP database).

export interface StateInfo {
  code: string;
  name: string;
  /** 2020 census population, millions. */
  pop: number;
  /** FIPS code, used to join the us-atlas state shapes. */
  fips: string;
}

export const STATES: StateInfo[] = [
  ["AL", "Alabama", 5.02, "01"], ["AK", "Alaska", 0.73, "02"], ["AZ", "Arizona", 7.15, "04"],
  ["AR", "Arkansas", 3.01, "05"], ["CA", "California", 39.54, "06"], ["CO", "Colorado", 5.77, "08"],
  ["CT", "Connecticut", 3.61, "09"], ["DE", "Delaware", 0.99, "10"], ["DC", "District of Columbia", 0.69, "11"],
  ["FL", "Florida", 21.54, "12"], ["GA", "Georgia", 10.71, "13"], ["HI", "Hawaii", 1.46, "15"],
  ["ID", "Idaho", 1.84, "16"], ["IL", "Illinois", 12.81, "17"], ["IN", "Indiana", 6.79, "18"],
  ["IA", "Iowa", 3.19, "19"], ["KS", "Kansas", 2.94, "20"], ["KY", "Kentucky", 4.51, "21"],
  ["LA", "Louisiana", 4.66, "22"], ["ME", "Maine", 1.36, "23"], ["MD", "Maryland", 6.18, "24"],
  ["MA", "Massachusetts", 7.03, "25"], ["MI", "Michigan", 10.08, "26"], ["MN", "Minnesota", 5.71, "27"],
  ["MS", "Mississippi", 2.96, "28"], ["MO", "Missouri", 6.15, "29"], ["MT", "Montana", 1.08, "30"],
  ["NE", "Nebraska", 1.96, "31"], ["NV", "Nevada", 3.1, "32"], ["NH", "New Hampshire", 1.38, "33"],
  ["NJ", "New Jersey", 9.29, "34"], ["NM", "New Mexico", 2.12, "35"], ["NY", "New York", 20.2, "36"],
  ["NC", "North Carolina", 10.44, "37"], ["ND", "North Dakota", 0.78, "38"], ["OH", "Ohio", 11.8, "39"],
  ["OK", "Oklahoma", 3.96, "40"], ["OR", "Oregon", 4.24, "41"], ["PA", "Pennsylvania", 13.0, "42"],
  ["RI", "Rhode Island", 1.1, "44"], ["SC", "South Carolina", 5.12, "45"], ["SD", "South Dakota", 0.89, "46"],
  ["TN", "Tennessee", 6.91, "47"], ["TX", "Texas", 29.15, "48"], ["UT", "Utah", 3.27, "49"],
  ["VT", "Vermont", 0.64, "50"], ["VA", "Virginia", 8.63, "51"], ["WA", "Washington", 7.71, "53"],
  ["WV", "West Virginia", 1.79, "54"], ["WI", "Wisconsin", 5.89, "55"], ["WY", "Wyoming", 0.58, "56"],
].map(([code, name, pop, fips]) => ({ code, name, pop, fips }) as StateInfo);
