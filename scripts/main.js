function openOffer() {
  const overlay = document.getElementById("offer-overlay");
  if (!overlay) return;

  overlay.classList.add("active");
  document.body.style.overflow = "hidden";
  overlay.scrollTop = 0;
}

function closeOffer() {
  const overlay = document.getElementById("offer-overlay");
  if (!overlay) return;

  overlay.classList.remove("active");
  document.body.style.overflow = "";
}

async function submitOffer(e) {
  e.preventDefault();

  const form = document.getElementById("offer-form");
  const success = document.getElementById("offer-success");
  if (!form || !success) return;

  const formData = new FormData(form);
  const object = Object.fromEntries(formData);

  object.message =
    "=== DEEPBLOE BOOKING OFFER FORM ===\n\n" +
    "--- OFFER DETAILS ---\n" +
    "Date(s): " + (object.dates || "") + "\n" +
    "Artist(s): " + (object.artists || "") + "\n" +
    "Fee: " + (object.fee || "") + "\n" +
    "Additional Terms: " + (object.additional_terms || "") + "\n" +
    "Flights: " + (object.flights || "") + " (" + (object.flights_type || "") + ")\n" +
    "Hotel: " + (object.hotel || "") + " (" + (object.hotel_type || "") + ")\n\n" +
    "--- YOUR DETAILS ---\n" +
    "Name: " + (object.contact_name || "") + "\n" +
    "Title: " + (object.contact_title || "") + "\n" +
    "Office: " + (object.contact_office || "") + "\n" +
    "Mobile: " + (object.contact_mobile || "") + "\n" +
    "Email: " + (object.contact_email || "") + "\n\n" +
    "--- PURCHASER ---\n" +
    "Company: " + (object.company_name || "") + "\n" +
    "Address: " + (object.company_address || "") + ", " + (object.company_city || "") + " " + (object.company_postal || "") + "\n" +
    "Phone: " + (object.company_phone || "") + "\n" +
    "Signatory: " + (object.signatory || "") + " | " + (object.signatory_mobile || "") + " | " + (object.signatory_email || "") + "\n\n" +
    "--- VENUE & EVENT ---\n" +
    "Event: " + (object.event_name || "") + "\n" +
    "Venue: " + (object.venue_name || "") + ", " + (object.venue_address || "") + ", " + (object.venue_city || "") + "\n" +
    "Phone: " + (object.venue_phone || "") + " | Website: " + (object.venue_website || "") + "\n" +
    "Capacity: " + (object.capacity || "") + " | Age: " + (object.age || "") + "\n" +
    "Tickets: " + (object.tickets || "") + "\n" +
    "Door/Show: " + (object.door_time || "") + " | Curfew: " + (object.curfew || "") + "\n" +
    "Venue Type: " + (object.venue_type || "") + "\n" +
    "Set Time: " + (object.set_time || "") + " | Stage: " + (object.stage || "") + "\n" +
    "Other Artists: " + (object.other_artists || "") + "\n" +
    "Other Set Times: " + (object.other_set_times || "") + "\n" +
    "Series: " + (object.series || "") + "\n\n" +
    "--- HISTORY ---\n" +
    "Venue History: " + (object.venue_history || "") + "\n" +
    "Agency History: " + (object.agency_history || "") + "\n" +
    "Comments: " + (object.comments || "");

  success.style.display = "block";
  success.textContent = "SENDING...";

  try {
    const response = await fetch("https://api.web3forms.com/submit", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: JSON.stringify(object)
    });

    const result = await response.json();

    if (response.status === 200 && result.success) {
      success.textContent = "OFFER SENT. WE'LL BE IN TOUCH SOON.";
      form.reset();
    } else {
      success.textContent = result.message || "Something went wrong.";
    }
  } catch (error) {
    success.textContent = "Something went wrong.";
  }
}

async function handleSubmit(e) {
  e.preventDefault();

  const form = document.getElementById("contact-form");
  const success = document.getElementById("form-success");
  if (!form || !success) return;

  const formData = new FormData(form);
  const object = Object.fromEntries(formData);

  object.message =
    "Name: " + (object.name || "") + "\n" +
    "Email: " + (object.email || "") + "\n" +
    "Type: " + (object.type || "") + "\n\n" +
    (object.message || "");

  success.style.display = "block";
  success.textContent = "SENDING...";

  try {
    const response = await fetch("https://api.web3forms.com/submit", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: JSON.stringify(object)
    });

    const result = await response.json();

    if (response.status === 200 && result.success) {
      success.textContent = "MESSAGE SENT. WE'LL BE IN TOUCH SOON.";
      form.reset();
    } else {
      success.textContent = result.message || "Something went wrong.";
    }
  } catch (error) {
    success.textContent = "Something went wrong.";
  }
}

function acceptCookies() {
  try {
    localStorage.setItem("cookies", "accepted");
  } catch (e) {}
  const banner = document.getElementById("cookie-banner");
  if (banner) banner.style.display = "none";
}

function rejectCookies() {
  try {
    localStorage.setItem("cookies", "rejected");
  } catch (e) {}
  const banner = document.getElementById("cookie-banner");
  if (banner) banner.style.display = "none";
}

function showPrivacy() {
  const modal = document.getElementById("privacy-modal");
  if (modal) modal.style.display = "block";
}

try {
  if (localStorage.getItem("cookies")) {
    const banner = document.getElementById("cookie-banner");
    if (banner) banner.style.display = "none";
  }
} catch (e) {}

// Nav scroll
window.addEventListener("scroll", function () {
  const nav = document.querySelector("nav");
  if (nav) nav.classList.toggle("scrolled", window.scrollY > 50);
});

// Reveal on scroll
(function () {
  const revealEls = document.querySelectorAll(".reveal");
  revealEls.forEach(function (el) {
    el.classList.add("animate-hidden");
  });

  const ro = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        entry.target.classList.remove("animate-hidden");
        entry.target.classList.add("visible");
        ro.unobserve(entry.target);
      }
    });
  }, {
    threshold: 0.1,
    rootMargin: "0px 0px -40px 0px"
  });

  revealEls.forEach(function (el) {
    ro.observe(el);
  });
})();

// Accordion
document.querySelectorAll(".service-row").forEach(function (row) {
  row.addEventListener("click", function () {
    const isOpen = row.classList.contains("open");
    document.querySelectorAll(".service-row").forEach(function (r) {
      r.classList.remove("open");
    });
    if (!isOpen) row.classList.add("open");
  });
});

// Counter
(function () {
  const els = document.querySelectorAll("[data-target]");
  if (!els.length) return;

  const io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (!e.isIntersecting || e.target._done) return;
      e.target._done = true;

      const target = +e.target.getAttribute("data-target");
      const span = e.target.querySelector(".count");
      if (!span) return;

      const t0 = performance.now();
      const dur = 1800;

      function tick(t) {
        const p = Math.min((t - t0) / dur, 1);
        span.textContent = Math.round((1 - Math.pow(1 - p, 3)) * target);
        if (p < 1) {
          requestAnimationFrame(tick);
        } else {
          span.textContent = target;
        }
      }

      requestAnimationFrame(tick);
      io.unobserve(e.target);
    });
  }, { threshold: 0.5 });

  els.forEach(function (el) {
    io.observe(el);
  });
})();
