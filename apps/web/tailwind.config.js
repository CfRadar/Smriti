/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        "primary": "#b84b25",
        "primary-container": "#c85a32",
        "on-primary": "#ffffff",
        "on-primary-container": "#ffede8",
        "secondary": "#8e4d32",
        "secondary-container": "#feaa88",
        "on-secondary-container": "#783c22",
        "tertiary": "#545836",
        "tertiary-container": "#6d704c",
        "on-surface": "#2b160e",
        "on-surface-variant": "#6e5449",
        "outline": "#8b716a",
        "outline-variant": "#dec0b7",
        "clay-sand": "#fbf7f2",
        "clay-cream": "#f5eee5",
        "clay-warm": "#ebe0d4",
        "clay-border": "#dfcfc0",
        "clay-ochre": "#c8864d",
        "clay-deep": "#703a22",
        "eucalyptus": "#7d8772",
        "eucalyptus-soft": "#e8ebe2",
        "eucalyptus-text": "#3a4430",
        "error": "#ba1a1a",
        "error-container": "#ffdad6",
        "on-error-container": "#93000a",
      },
      fontFamily: {
        newsreader: ["Newsreader", "serif"],
        literata: ["Literata", "serif"],
      }
    },
  },
  plugins: [],
}
