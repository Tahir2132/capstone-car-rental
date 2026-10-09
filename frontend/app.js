// Locally the search goes to local_server.py, on AWS to API Gateway.
// Replace the URL below with the Invoke URL of your API + /api/vehicles
const API_URL = ["localhost", "127.0.0.1"].includes(location.hostname)
  ? "/api/vehicles"
  : "https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/api/vehicles";

const form = document.getElementById("search-form");
const fromInput = document.getElementById("from");
const toInput = document.getElementById("to");
const statusEl = document.getElementById("status");
const resultsEl = document.getElementById("results");
const button = document.getElementById("search-btn");

const euro = new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR", maximumFractionDigits: 0 });
const shortDate = new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short" });

// Default dates: tomorrow until four days later
function isoDate(d) { return d.toISOString().slice(0, 10); }
const today = new Date();
const tomorrow = new Date(today); tomorrow.setDate(today.getDate() + 1);
const later = new Date(today); later.setDate(today.getDate() + 5);
fromInput.value = isoDate(tomorrow);
toInput.value = isoDate(later);
fromInput.min = isoDate(today);
toInput.min = isoDate(tomorrow);
fromInput.addEventListener("change", () => { toInput.min = fromInput.value; });

function carIcon(color) {
  return `<svg viewBox="0 0 150 60" aria-hidden="true">
    <path d="M10 42 L14 30 Q18 24 30 23 L48 22 L62 11 Q66 8 74 8 L102 8 Q110 8 116 13 L128 23 Q140 25 142 32 L142 42 Z"
          fill="${color}" stroke="#1B2430" stroke-width="2" stroke-linejoin="round"/>
    <path d="M66 21 L74 13 L98 13 Q104 13 108 17 L113 21 Z" fill="#E8EEF4" stroke="#1B2430" stroke-width="1.5"/>
    <circle cx="38" cy="44" r="10" fill="#1B2430"/><circle cx="38" cy="44" r="4" fill="#B8BEC6"/>
    <circle cx="114" cy="44" r="10" fill="#1B2430"/><circle cx="114" cy="44" r="4" fill="#B8BEC6"/>
  </svg>`;
}

function escapeHtml(text) {
  return String(text).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

function renderCars(data) {
  const from = shortDate.format(new Date(data.from));
  const to = shortDate.format(new Date(data.to));
  const dayWord = data.days === 1 ? "day" : "days";

  if (data.count === 0) {
    statusEl.innerHTML = `No cars of this type in <strong>${escapeHtml(data.location)}</strong>. Choose "All types" or another city.`;
    resultsEl.innerHTML = "";
    return;
  }

  statusEl.innerHTML = `<strong>${data.count} cars</strong> in ${escapeHtml(data.location)} for ${data.days} ${dayWord}, ${from} to ${to}. Cheapest first.`;
  resultsEl.innerHTML = data.vehicles.map(car => `
    <li class="car">
      ${car.image
        ? `<img src="${escapeHtml(car.image)}" alt="${escapeHtml(car.brand + " " + car.model)}" loading="lazy" onerror="this.replaceWith(document.createRange().createContextualFragment(carIcon('${escapeHtml(car.color)}')))">`
        : carIcon(escapeHtml(car.color))}
      <div>
        <h2><span class="brand">${escapeHtml(car.brand)}</span>${escapeHtml(car.model)}</h2>
        <ul class="specs">
          <li>${escapeHtml(car.category)}</li>
          <li>${car.seats} seats</li>
          <li>${escapeHtml(car.transmission)}</li>
          <li>${escapeHtml(car.fuel)}</li>
        </ul>
        ${car.description ? `<p class="desc">${escapeHtml(car.description)}</p>` : ""}
      </div>
      <span class="plate" title="Vehicle ID"><span class="eu">D</span><span class="id">${escapeHtml(car.vehicleId)}</span></span>
      <div class="price">
        <span class="total">${euro.format(car.totalPrice)}</span>
        <span class="per-day">${euro.format(car.pricePerDay)} per day</span><br>
        <button type="button" disabled title="Booking comes in phase 2">Book this car</button>
      </div>
    </li>`).join("");
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  const params = new URLSearchParams({
    location: document.getElementById("location").value,
    from: fromInput.value,
    to: toInput.value,
  });
  const category = document.getElementById("category").value;
  if (category) params.set("category", category);

  button.disabled = true;
  statusEl.classList.remove("error");
  statusEl.textContent = "Searching cars…";

  try {
    const res = await fetch(`${API_URL}?${params}`);
    let data;
    try { data = await res.json(); }
    catch { throw new Error("The search service isn't reachable yet. Check the API URL in app.js."); }
    if (!res.ok) throw new Error(data.error || "The search didn't work. Try again.");
    renderCars(data);
  } catch (err) {
    resultsEl.innerHTML = "";
    statusEl.classList.add("error");
    statusEl.textContent = err.message.includes("fetch")
      ? "Can't reach the server. Check that local_server.py is running."
      : err.message;
  } finally {
    button.disabled = false;
  }
});
