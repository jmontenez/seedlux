/// DLI — Daily Light Integral (mol·m⁻²·j⁻¹).
///
/// DLI = PPFD (µmol·m⁻²·s⁻¹) × photopériode (h) × 3600 s/h ÷ 1 000 000.
double dli(double ppfd, double photoperiodHours) =>
    ppfd * photoperiodHours * 0.0036;
