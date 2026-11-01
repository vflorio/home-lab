// Homelab link chips
//
// Turns service descriptions written as
//   "<descrizione> │ 🌐 <host> │ 🏠 <host> │ 🔌 <ip:porta> │ 🔒 <testo>"
// into a short description plus a row of chips (see the convention in services.yaml).
// The chips are placed next to the card title, not inside it, so they are never nested in the card <a>.

(() => {
  const SEPARATOR = "│";
  const KINDS = {
    "🌐": { kind: "wan", scheme: "https://", title: "Internet" },
    "🏠": { kind: "lan", scheme: "https://", title: "Intranet" },
    "🔌": { kind: "ip", scheme: "http://", title: "IP:porta" },
    "🔒": { kind: "tcp", scheme: null, title: "Non HTTP / solo interno: clic per copiare" },
  };

  function buildChip(token) {
    const icon = Object.keys(KINDS).find((key) => token.startsWith(key));
    const value = icon ? token.slice(icon.length).trim() : token;
    const { kind, scheme, title } = icon ? KINDS[icon] : KINDS["🔒"];

    const hasScheme = /^[a-z]+:\/\//.test(value);
    const label = value.replace(/^[a-z]+:\/\//, "").replace(/\/$/, "");
    const chip = document.createElement(scheme ? "a" : "span");
    chip.className = `hl-chip hl-chip-${kind}`;
    chip.title = title;
    chip.textContent = `${icon ?? "🔒"} ${label}`;

    if (scheme) {
      chip.href = hasScheme ? value : scheme + value;
      chip.target = "_blank";
      chip.rel = "noreferrer";
    } else {
      chip.addEventListener("click", () => {
        navigator.clipboard?.writeText(label).then(() => {
          chip.classList.add("hl-chip-copied");
          setTimeout(() => chip.classList.remove("hl-chip-copied"), 900);
        });
      });
    }
    return chip;
  }

  function enhance(card) {
    if (card.dataset.hlLinks) return;
    const description = card.querySelector(".service-description");
    if (!description || !description.textContent.includes(SEPARATOR)) return;
    card.dataset.hlLinks = "1";

    const [text, ...tokens] = description.textContent.split(SEPARATOR).map((part) => part.trim());

    const shortDescription = document.createElement("p");
    shortDescription.className = "hl-description text-xs font-light";
    shortDescription.textContent = text;
    description.after(shortDescription);

    const row = document.createElement("div");
    row.className = "hl-links";
    tokens.filter(Boolean).forEach((token) => row.appendChild(buildChip(token)));
    card.querySelector(".service-title").after(row);
  }

  function scan() {
    document.querySelectorAll(".service-card:not([data-hl-links])").forEach(enhance);
  }

  // cards are (re)mounted on tab switches and group toggles
  new MutationObserver(scan).observe(document.body, { childList: true, subtree: true });
  scan();
})();
