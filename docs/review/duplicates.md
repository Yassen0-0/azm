# Truly identical exercise pairs (Arabic names)

These groups have the same movement in the source data: same equipment, same target, and instructions that say the same thing (only wording or one secondary muscle differs). Each group shares one Arabic name on purpose, so `tools/build_catalog.sh --check` warns about them. **Integrator: at merge, hide every id in the "hide" column and keep the "keep" id.** The keep id is the reviewed one if there is one, otherwise the plain (non-"v. 2") English name.

32 groups, 33 ids to hide.

| Arabic name | keep | hide | English (keep → hide) | why identical |
|---|---|---|---|---|
| طعن خلفي بار | 0078 | 0077 | barbell rear lunge → barbell rear lunge v. 2 | same cues, wording only |
| سواعد عكسي بار | 0082 | 0079 | barbell reverse wrist curl → barbell revers wrist curl v. 2 | same cues, wording only |
| سحب بار للدقن | 0120 | 0119, 0121 | barbell upright row → barbell upright row v. 2; barbell upright row v. 3 | v. 2 / v. 3 differ only in wording |
| بول أوفر كابل | 0238 | 0199 | cable straight arm pulldown → cable pushdown (straight arm) v. 2 | straight-arm pushdown = straight-arm pulldown; v. 2 only adds a slight knee bend |
| أرنولد | 2137 | 0287 | dumbbell arnold press → dumbbell arnold press v. 2 | same cues, wording only |
| ضغط دمبل ضيق | 1731 | 0296 | dumbbell close grip press → dumbbell close-grip press | same cues, wording only |
| رفرفة أمامي | 0310 (reviewed) | 0309 | dumbbell front raise → dumbbell front raise v. 2 | same cues, wording only |
| هامر | 0313 (reviewed) | 0312 | dumbbell hammer curl → dumbbell hammer curl v. 2 | same cues, wording only |
| باي مايل | 0318 | 0317 | dumbbell incline curl → dumbbell incline curl v. 2 | same cues, wording only |
| ضغط كتف دمبل بدراع واحد | 0361 | 0360 | dumbbell one arm shoulder press → dumbbell one arm shoulder press v. 2 | same cues, wording only |
| باي دمبل عكسي | 1654 | 0382 | dumbbell biceps curl reverse → dumbbell revers grip biceps curl | same cues, wording only |
| باي دمبل قاعد | 1677 | 0391 | dumbbell seated bicep curl → dumbbell seated curl | palms "forward" vs "up" (same supinated grip) |
| رفرفة جانبي قاعد | 0396 | 0395 | dumbbell seated lateral raise → dumbbell seated lateral raise v. 2 | same cues, wording only |
| ديدلفت دمبل رجل مفرودة | 0432 | 0434 | dumbbell stiff leg deadlift → dumbbell straight leg deadlift | stiff-leg vs straight-leg: same cues (slight knee bend, hinge) |
| ضغط صدر جهاز | 0576 (reviewed) | 0577 | lever chest press → lever chest press | instructions word-for-word identical, same English name |
| ضغط على بوسو | 1307 | 0653 | push up on bosu ball → push-up (bosu ball) | identical instructions |
| ضغط على كورة | 0655 | 0656 | push-up (on stability ball) → push-up (on stability ball) | same English name, identical instructions |
| ضغط على الحيطة | 0659 | 0658 | push-up (wall) → push-up (wall) v. 2 | same cues, wording only |
| عقلة مقلوب | 1326 (reviewed) | 0674 | chin-up → reverse grip pull-up | reverse-grip pull-up = chin-up |
| بطن تلات تربع | 0001 | 0735 | 3/4 sit-up → sit-up v. 2 | instructions word-for-word identical (sit-up v. 2 is the 3/4 sit-up) |
| سكوات سميث | 3281 | 0770 | smith full squat → smith squat | "full" vs plain: same depth cue (parallel or below) |
| ضغط كتف جهاز لقدام وفوق | 0869 | 2318 | lever shoulder press v. 2 → lever shoulder press v. 3 | v. 2 and v. 3 have word-for-word identical instructions; both differ from 0603 (they push up **and forward**, wider grip) |
| سحب تي بار عكسي | 1349 | 1351 | lever reverse t-bar row → lever t-bar reverse grip row | both use an overhand grip despite "reverse grip" in one name |
| سمانة عكسي سميث | 0763 | 1394 | smith reverse calf raises → smith reverse calf raises | same cues, wording only |
| ضغط صدر عالي جهاز | 1299 | 1479 | lever incline chest press → lever incline chest press v. 2 | same cues, wording only |
| كرانش جانبي أرض | 0635 | 1495 | oblique crunches floor → oblique crunch v. 2 | instructions identical apart from floor/ground |
| باي ارتكاز جهاز | 0592 | 1614 | lever preacher curl → lever preacher curl v. 2 | v. 2 only adds "chest against the support" |
| سبايدر كيرل زد | 0454 | 1628 | ez barbell spider curl → ez barbell spider curl | same English name, identical instructions |
| هامر عرضي | 0298 | 1657 | dumbbell cross body hammer curl → dumbbell cross body hammer curl v. 2 | same cues, wording only |
| باي دراع واحد على ظهر بنش عالي | 0422 | 1680 | dumbbell standing one arm curl (over incline bench) → dumbbell standing one arm curl over incline bench | same cues, wording only |
| كوبان برس | 0299 | 2136 | dumbbell cuban press → dumbbell cuban press v. 2 | same cues, wording only |
| روشن تويست بوزن | 0846 | 2371 | weighted russian twist → weighted russian twist v. 2 | same cues, wording only |
