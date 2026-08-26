import Toybox.Application;
import Toybox.ActivityMonitor;
import Toybox.UserProfile;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;

// Shared by the full view and the glance, so everything here carries the
// (:glance) annotation to exist in both code scopes.

(:glance)
const DEFAULT_CALORIES_PER_BEER = 80;
(:glance)
const CALORIES_PER_BEER_KEY = "caloriesPerBeer";
(:glance)
const MIN_CALORIES_PER_BEER = 30;
(:glance)
const MAX_CALORIES_PER_BEER = 400;
(:glance)
const CALORIES_PER_BEER_STEP = 5;

// Used when the watch's user profile is incomplete. Without it an empty
// profile would credit the whole resting burn as "earned".
(:glance)
const FALLBACK_BMR = 1600.0;

// User-adjustable via the on-watch stepper (MENU from the main view).
(:glance)
function getCaloriesPerBeer() as Number {
    var stored = Storage.getValue(CALORIES_PER_BEER_KEY);
    if (stored instanceof Lang.Number) {
        return clampCaloriesPerBeer(stored);
    }
    return DEFAULT_CALORIES_PER_BEER;
}

(:glance)
function clampCaloriesPerBeer(value as Number) as Number {
    if (value < MIN_CALORIES_PER_BEER) {
        return MIN_CALORIES_PER_BEER;
    }
    if (value > MAX_CALORIES_PER_BEER) {
        return MAX_CALORIES_PER_BEER;
    }
    return value;
}

// ActivityMonitor reports the day's TOTAL kcal, which includes resting (BMR)
// burn — roughly 1,600-2,000 kcal just for being alive. Only calories burned
// by actually moving should buy a beer, so subtract the share of BMR that has
// elapsed since midnight.
(:glance)
function getActiveCalories() as Number {
    var info = ActivityMonitor.getInfo();
    var total = 0;
    if (info != null) {
        var reported = info.calories;
        if (reported != null) {
            total = reported;
        }
    }

    var active = total - restingBurnSoFar();
    return active > 0 ? active.toNumber() : 0;
}

(:glance)
function getBeersEarned() as Float {
    return getActiveCalories() / (getCaloriesPerBeer() * 1.0);
}

(:glance)
function restingBurnSoFar() as Float {
    var clock = System.getClockTime();
    var minutesElapsed = clock.hour * 60 + clock.min;
    return estimateBmr() * (minutesElapsed / 1440.0);
}

// Mifflin-St Jeor equation. Profile weight is grams, height centimetres.
(:glance)
function estimateBmr() as Float {
    // getProfile() is non-nullable, so no null check on the profile itself -
    // but its individual fields are unset until the user fills them in.
    var profile = UserProfile.getProfile();

    var weightG = profile.weight;
    var heightCm = profile.height;
    var birthYear = profile.birthYear;
    if (weightG == null || heightCm == null || birthYear == null) {
        return FALLBACK_BMR;
    }

    var age = Gregorian.info(Time.now(), Time.FORMAT_SHORT).year - birthYear;
    if (age < 10 || age > 120) {
        age = 40;
    }

    var bmr = 10.0 * (weightG / 1000.0) + 6.25 * heightCm - 5.0 * age;
    bmr += (profile.gender == UserProfile.GENDER_FEMALE) ? -161.0 : 5.0;

    return bmr > 0 ? bmr : FALLBACK_BMR;
}
