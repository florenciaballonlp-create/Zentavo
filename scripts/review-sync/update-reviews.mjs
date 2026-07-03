import fs from "node:fs/promises";
import path from "node:path";
import gplay from "google-play-scraper";

const OUT_FILE = process.env.REVIEWS_OUTPUT || "docs/assets/reviews.json";
const APPLE_APP_ID = process.env.APPLE_APP_ID || "";
const GOOGLE_PLAY_APP_ID = process.env.GOOGLE_PLAY_APP_ID || "";
const MAX_REVIEWS = Number(process.env.MAX_REVIEWS || 24);

const LANG_MATRIX = [
  { lang: "es", country: "ar" },
  { lang: "en", country: "us" },
  { lang: "pt", country: "br" },
  { lang: "it", country: "it" },
  { lang: "ja", country: "jp" },
  { lang: "zh", country: "cn" }
];

function normalizeText(value) {
  return String(value || "")
    .replace(/\s+/g, " ")
    .trim();
}

function isUsefulReview(text) {
  const normalized = normalizeText(text);
  return normalized.length >= 30;
}

function parseAppleEntries(payload) {
  const entries = payload?.feed?.entry;
  if (!Array.isArray(entries)) return [];

  return entries
    .map((entry) => {
      const quote = normalizeText(entry?.content?.label);
      const author = normalizeText(entry?.author?.name?.label);
      const rating = Number(entry?.["im:rating"]?.label || 0);
      const date = entry?.updated?.label || null;

      if (!quote || !author || Number.isNaN(rating)) return null;
      return {
        quote,
        author,
        rating,
        date,
        store: "apple"
      };
    })
    .filter(Boolean);
}

async function fetchAppleReviews() {
  if (!APPLE_APP_ID) return [];

  const all = [];
  for (const locale of LANG_MATRIX) {
    const url = `https://itunes.apple.com/${locale.country}/rss/customerreviews/page=1/id=${APPLE_APP_ID}/sortby=mostrecent/json`;
    try {
      const response = await fetch(url, { cache: "no-store" });
      if (!response.ok) continue;
      const data = await response.json();
      const rows = parseAppleEntries(data).map((review) => ({ ...review, lang: locale.lang }));
      all.push(...rows);
    } catch {
      // Skip locale errors and keep trying remaining locales.
    }
  }

  return all;
}

async function fetchGoogleReviews() {
  if (!GOOGLE_PLAY_APP_ID) return [];

  const all = [];
  for (const locale of LANG_MATRIX) {
    try {
      const response = await gplay.reviews({
        appId: GOOGLE_PLAY_APP_ID,
        sort: gplay.sort.NEWEST,
        num: 50,
        lang: locale.lang,
        country: locale.country
      });

      const rows = (response?.data || []).map((item) => ({
        quote: normalizeText(item?.text),
        author: normalizeText(item?.userName || "Usuario Google Play"),
        rating: Number(item?.score || 0),
        date: item?.date ? new Date(item.date).toISOString() : null,
        store: "google",
        lang: locale.lang
      }));

      all.push(...rows);
    } catch {
      // Skip locale errors and keep trying remaining locales.
    }
  }

  return all;
}

function selectAndFormatReviews(reviews) {
  const seen = new Set();

  return reviews
    .filter((review) => review.rating >= 4)
    .filter((review) => isUsefulReview(review.quote))
    .filter((review) => {
      const key = normalizeText(review.quote).toLowerCase();
      if (!key || seen.has(key)) return false;
      seen.add(key);
      return true;
    })
    .sort((a, b) => {
      const dateA = a.date ? Date.parse(a.date) : 0;
      const dateB = b.date ? Date.parse(b.date) : 0;
      return dateB - dateA;
    })
    .slice(0, MAX_REVIEWS)
    .map((review) => ({
      quote: review.quote,
      author: `${review.author} · ${review.store === "apple" ? "App Store" : "Google Play"}`
    }));
}

async function main() {
  if (!APPLE_APP_ID && !GOOGLE_PLAY_APP_ID) {
    console.log("No se configuraron APPLE_APP_ID ni GOOGLE_PLAY_APP_ID. Se mantiene el archivo actual.");
    return;
  }

  const [appleReviews, googleReviews] = await Promise.all([
    fetchAppleReviews(),
    fetchGoogleReviews()
  ]);

  const formatted = selectAndFormatReviews([...appleReviews, ...googleReviews]);

  if (!formatted.length) {
    console.log("No se encontraron reseñas válidas en esta ejecución. Se mantiene el archivo actual.");
    return;
  }

  const outputPath = path.resolve(process.cwd(), OUT_FILE);
  const payload = {
    reviews: formatted,
    meta: {
      updatedAt: new Date().toISOString(),
      source: "app-store-and-google-play"
    }
  };

  await fs.writeFile(outputPath, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
  console.log(`Reseñas actualizadas: ${formatted.length} -> ${OUT_FILE}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
