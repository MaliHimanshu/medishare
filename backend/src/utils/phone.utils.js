/**
 * Phone Number Utilities
 * -----------------------
 * Normalizes phone numbers to E.164 format.
 * Specifically handles Indian mobile numbers (+91) and international formats.
 */

/**
 * Normalizes a phone number to standard E.164 format.
 * Examples:
 *   '9876543210'        -> '+919876543210'
 *   '09876543210'       -> '+919876543210'
 *   '919876543210'      -> '+919876543210'
 *   '+919876543210'     -> '+919876543210'
 *   '+9109876543210'    -> '+919876543210'
 *   '+91 98765 43210'   -> '+919876543210'
 *   '+14155552671'      -> '+14155552671'
 *
 * @param {string} phone
 * @returns {string} E.164 formatted phone number
 */
function normalizePhoneNumber(phone) {
  if (!phone || typeof phone !== "string") {
    throw new Error("Phone number is required");
  }

  // Strip all whitespace, hyphens, parentheses, and dots
  let cleaned = phone.replace(/[\s\-\(\)\.]/g, "").trim();

  if (!cleaned) {
    throw new Error("Phone number cannot be empty");
  }

  // Case 1: Starts with '+91'
  if (cleaned.startsWith("+91")) {
    let rest = cleaned.slice(3);
    // Strip any accidental leading zeros (e.g., +9109876543210 -> +919876543210)
    while (rest.startsWith("0")) {
      rest = rest.slice(1);
    }
    cleaned = `+91${rest}`;
  }
  // Case 2: Starts with '0091' (international dialing prefix)
  else if (cleaned.startsWith("0091")) {
    let rest = cleaned.slice(4);
    while (rest.startsWith("0")) {
      rest = rest.slice(1);
    }
    cleaned = `+91${rest}`;
  }
  // Case 3: Starts with '91' and followed by 10 digits (12 digits total)
  else if (/^91[6-9]\d{9}$/.test(cleaned)) {
    cleaned = `+${cleaned}`;
  }
  // Case 4: Starts with single leading '0' followed by 10 digits (e.g., 09876543210)
  else if (/^0[6-9]\d{9}$/.test(cleaned)) {
    cleaned = `+91${cleaned.slice(1)}`;
  }
  // Case 5: Exactly 10 digits (standard Indian mobile number starting with 6-9)
  else if (/^[6-9]\d{9}$/.test(cleaned)) {
    cleaned = `+91${cleaned}`;
  }
  // Case 6: Generic 10 digits
  else if (/^\d{10}$/.test(cleaned)) {
    cleaned = `+91${cleaned}`;
  }
  // Case 7: Already starts with '+'
  else if (cleaned.startsWith("+")) {
    // Keep as is, will validate below
  }
  // Case 8: Other digits without '+'
  else {
    cleaned = `+${cleaned}`;
  }

  // Validate E.164 format: '+' followed by 10 to 15 digits
  const e164Regex = /^\+[1-9]\d{9,14}$/;
  if (!e164Regex.test(cleaned)) {
    throw new Error(
      `Invalid phone number format (${phone}). Please provide a valid 10-digit mobile number.`
    );
  }

  return cleaned;
}

module.exports = {
  normalizePhoneNumber,
};
