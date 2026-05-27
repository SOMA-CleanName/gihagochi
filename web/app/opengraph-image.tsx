import { ImageResponse } from "next/og";

export const alt = "encore — Grow your idol, together.";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function OgImage() {
  return new ImageResponse(
    (
      <div
        style={{
          height: "100%",
          width: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "flex-start",
          justifyContent: "space-between",
          padding: 80,
          backgroundColor: "#FFFFFF",
          backgroundImage:
            "radial-gradient(circle at 85% 15%, rgba(103,80,164,0.22), transparent 50%), radial-gradient(circle at 15% 90%, rgba(103,80,164,0.12), transparent 55%)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 18 }}>
          <div
            style={{
              width: 64,
              height: 64,
              borderRadius: 16,
              backgroundColor: "#6750A4",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#FFFFFF",
              fontWeight: 800,
              fontSize: 36,
            }}
          >
            E
          </div>
          <span
            style={{ fontSize: 32, fontWeight: 600, color: "#0A0A0A" }}
          >
            encore
          </span>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 28 }}>
          <p
            style={{
              fontSize: 96,
              fontWeight: 700,
              lineHeight: 1.05,
              letterSpacing: "-0.025em",
              color: "#0A0A0A",
              margin: 0,
            }}
          >
            Grow your idol,
            <br />
            together.
          </p>
          <p
            style={{
              fontSize: 32,
              fontWeight: 500,
              color: "#52525B",
              margin: 0,
              letterSpacing: "0.02em",
            }}
          >
            Watch · Talk · Cheer · Grow
          </p>
        </div>
      </div>
    ),
    size,
  );
}
