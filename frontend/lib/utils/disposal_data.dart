/// GreenBin Genius – Disposal Guidance Data
/// Local structured lookup mirroring the backend DISPOSAL_TIPS dict.
/// Used by the classification result screen to show step-by-step guidance
/// without an extra round-trip to the server.
/// When the admin updates tips in the DB, call ApiService.getDisposalGuidance()
/// instead to get the live version.

class DisposalStep {
  final String en;
  final String ur;
  const DisposalStep(this.en, this.ur);
}

class DisposalGuidance {
  final String category;
  final String tipEn;
  final String tipUr;
  final String binColor;      // e.g. "Blue"
  final String icon;          // emoji
  final List<String> steps;
  final List<String> stepsUr;
  final List<String> doList;
  final List<String> dontList;

  const DisposalGuidance({
    required this.category,
    required this.tipEn,
    required this.tipUr,
    required this.binColor,
    required this.icon,
    required this.steps,
    required this.stepsUr,
    required this.doList,
    required this.dontList,
  });

  /// Hex colour for the bin badge
  String get binColorHex {
    switch (binColor.toLowerCase()) {
      case 'blue':   return '#2196F3';
      case 'green':  return '#4CAF50';
      case 'yellow': return '#FFC107';
      case 'red':    return '#F44336';
      case 'purple': return '#9C27B0';
      case 'brown':  return '#795548';
      case 'black':  return '#424242';
      case 'orange': return '#FF9800';
      default:       return '#757575';
    }
  }
}

/// ── Static lookup ─────────────────────────────────────────────────────────
const _defaultGuidance = DisposalGuidance(
  category:  'other',
  tipEn:     'Dispose of responsibly.',
  tipUr:     'ذمہ داری سے ٹھکانیں۔',
  binColor:  'Black',
  icon:      '🗑️',
  steps:     ['Place item in the nearest appropriate waste bin.'],
  stepsUr:   ['قریب ترین مناسب کچرے کے ڈبے میں ڈالیں۔'],
  doList:    ['Dispose responsibly'],
  dontList:  ["Don't litter"],
);

const Map<String, DisposalGuidance> kDisposalData = {
  'plastic': DisposalGuidance(
    category:  'plastic',
    tipEn:     'Rinse and place in the plastic recycling (blue) bin.',
    tipUr:     'صاف کریں اور نیلے پلاسٹک ری سائیکلنگ ڈبے میں ڈالیں۔',
    binColor:  'Blue',
    icon:      '🧴',
    steps: [
      'Check the recycling number (1-7) stamped on the bottom of the item.',
      'Empty the container completely — remove all food or liquid residue.',
      'Rinse with water to remove any leftover contents.',
      'Remove non-plastic parts such as metal lids, foam inserts, or rubber seals.',
      'Flatten bottles and containers to save space in the bin.',
      'Do NOT place plastic bags or film inside the recycling bin.',
      'Place the cleaned plastic item in the blue recycling bin.',
      "If in doubt, check your local municipality's accepted plastics list.",
    ],
    stepsUr: [
      'آئٹم کے نچلے حصے پر ری سائیکلنگ نمبر (1-7) چیک کریں۔',
      'کنٹینر کو مکمل طور پر خالی کریں — تمام خوراک یا مائع ہٹا دیں۔',
      'بقایا مواد ہٹانے کے لیے پانی سے دھوئیں۔',
      'دھاتی ڈھکن، فوم انسرٹ، یا ربڑ کی سیل جیسے غیر پلاسٹک حصے ہٹا دیں۔',
      'جگہ بچانے کے لیے بوتلیں اور کنٹینرز چپٹے کریں۔',
      'پلاسٹک بیگز یا فلم ری سائیکلنگ ڈبے میں نہ ڈالیں۔',
      'صاف پلاسٹک آئٹم نیلے ری سائیکلنگ ڈبے میں ڈالیں۔',
      'شک ہو تو اپنی بلدیہ کی قبول شدہ پلاسٹک کی فہرست دیکھیں۔',
    ],
    doList:    ['Rinse before recycling', 'Flatten containers', 'Check the recycle number', 'Remove metal/rubber parts'],
    dontList:  ["Don't recycle greasy plastic", "Don't put plastic bags in the bin", "Don't mix non-recyclables"],
  ),

  'glass': DisposalGuidance(
    category:  'glass',
    tipEn:     'Rinse and place in the glass recycling bin.',
    tipUr:     'صاف کریں اور شیشہ ری سائیکلنگ ڈبے میں ڈالیں۔',
    binColor:  'Green',
    icon:      '🫙',
    steps: [
      'Confirm the item is made of glass — not ceramic, Pyrex, or crystal.',
      'Empty the glass container of all contents.',
      'Rinse with water to remove food, liquid, or residue.',
      'Remove metal or plastic lids and recycle them separately.',
      'Remove paper labels if possible (not strictly required).',
      'Do NOT break the glass — it can injure waste workers.',
      'Do NOT recycle broken glass, mirrors, or window panes in this bin.',
      'Place the clean glass bottle or jar in the green glass recycling bin.',
    ],
    stepsUr: [
      'تصدیق کریں کہ آئٹم شیشے سے بنی ہے — سیرامک، پائریکس، یا کرسٹل نہیں۔',
      'شیشے کے کنٹینر کو تمام مواد سے خالی کریں۔',
      'خوراک، مائع یا بقایا ہٹانے کے لیے پانی سے دھوئیں۔',
      'دھاتی یا پلاسٹک کے ڈھکن ہٹا کر الگ ری سائیکل کریں۔',
      'کاغذی لیبل ممکن ہو تو ہٹا دیں (ضروری نہیں)۔',
      'شیشہ نہ توڑیں — یہ کچرا کارکنوں کو زخمی کر سکتا ہے۔',
      'ٹوٹا ہوا شیشہ، آئینہ یا کھڑکی کے شیشے اس ڈبے میں نہ ڈالیں۔',
      'صاف شیشے کی بوتل یا جار سبز شیشہ ری سائیکلنگ ڈبے میں ڈالیں۔',
    ],
    doList:    ['Rinse bottles and jars', 'Remove metal/plastic lids', 'Recycle lids separately'],
    dontList:  ["Don't break glass", "Don't recycle mirrors or windows", "Don't recycle ceramics"],
  ),

  'metal': DisposalGuidance(
    category:  'metal',
    tipEn:     'Rinse and place in the metal recycling bin.',
    tipUr:     'صاف کریں اور دھات ری سائیکلنگ ڈبے میں ڈالیں۔',
    binColor:  'Yellow',
    icon:      '🥫',
    steps: [
      'Identify the metal type — steel, aluminium, tin, or copper.',
      'Empty the can or metal container completely.',
      'Rinse with water to remove food or liquid residue.',
      'Crush aluminium cans to save bin space (optional but recommended).',
      'Remove any plastic lids, rubber seals, or non-metal parts.',
      'Do NOT put aerosol cans in fire or attempt to puncture them.',
      'Foil and aluminium trays can also be recycled after rinsing.',
      'Place the clean metal item in the yellow metal recycling bin.',
    ],
    stepsUr: [
      'دھات کی قسم شناخت کریں — اسٹیل، ایلومینیم، ٹین، یا تانبا۔',
      'کین یا دھاتی کنٹینر کو مکمل خالی کریں۔',
      'خوراک یا مائع بقایا ہٹانے کے لیے پانی سے دھوئیں۔',
      'جگہ بچانے کے لیے ایلومینیم کین کو کچل دیں (اختیاری لیکن مستحسن)۔',
      'کوئی بھی پلاسٹک ڈھکن، ربڑ کی سیل، یا غیر دھاتی حصے ہٹا دیں۔',
      'ایروسول کین کو آگ میں نہ ڈالیں یا سوراخ کرنے کی کوشش نہ کریں۔',
      'فوائل اور ایلومینیم ٹرے دھونے کے بعد ری سائیکل کی جا سکتی ہیں۔',
      'صاف دھاتی آئٹم پیلے دھاتی ری سائیکلنگ ڈبے میں ڈالیں۔',
    ],
    doList:    ['Rinse cans and tins', 'Crush aluminium cans', 'Recycle aluminium foil after rinsing'],
    dontList:  ["Don't put aerosols in fire", "Don't mix with general waste", "Don't include non-metal parts"],
  ),

  'e-waste': DisposalGuidance(
    category:  'e-waste',
    tipEn:     'Take to an authorised e-waste collection centre.',
    tipUr:     'مجاز ای-ویسٹ مرکز پر لے جائیں۔',
    binColor:  'Red',
    icon:      '💻',
    steps: [
      'Do NOT throw e-waste in general waste bins — it contains toxic materials.',
      'Back up any personal data stored on the device.',
      'Perform a factory reset to wipe your personal information.',
      'Remove batteries if possible and dispose of them separately.',
      'Check if the manufacturer offers a take-back or recycling programme.',
      'Find the nearest authorised e-waste collection centre using the bin locator.',
      'Keep original packaging if available to transport safely.',
      'Drop the device at the e-waste centre — do not leave it on the street.',
    ],
    stepsUr: [
      'ای-ویسٹ کو عام کچرے کے ڈبوں میں نہ پھینکیں — اس میں زہریلا مواد ہوتا ہے۔',
      'ڈیوائس پر محفوظ کوئی بھی ذاتی ڈیٹا بیک اپ کریں۔',
      'اپنی ذاتی معلومات مٹانے کے لیے فیکٹری ری سیٹ کریں۔',
      'اگر ممکن ہو تو بیٹریاں ہٹا کر الگ سے ٹھکانے لگائیں۔',
      'چیک کریں کہ آیا مینوفیکچرر ٹیک-بیک یا ری سائیکلنگ پروگرام پیش کرتا ہے۔',
      'بن لوکیٹر سے قریب ترین مجاز ای-ویسٹ مرکز تلاش کریں۔',
      'دستیاب ہو تو اصل پیکیجنگ محفوظ نقل و حمل کے لیے استعمال کریں۔',
      'ڈیوائس ای-ویسٹ مرکز پر ڈراپ کریں — سڑک پر مت چھوڑیں۔',
    ],
    doList:    ['Wipe personal data first', 'Remove batteries separately', 'Use authorised collection centres'],
    dontList:  ["Don't throw in general waste", "Don't burn e-waste", "Don't leave on the street"],
  ),

  'textile': DisposalGuidance(
    category:  'textile',
    tipEn:     'Donate if usable; otherwise place in textile bins.',
    tipUr:     'اگر قابل استعمال ہو تو عطیہ کریں، ورنہ ٹیکسٹائل ڈبے میں ڈالیں۔',
    binColor:  'Purple',
    icon:      '👕',
    steps: [
      'Assess the condition: is it wearable, repairable, or beyond use?',
      'If wearable: wash, fold, and donate to a charity or clothing drive.',
      'If repairable: take to a tailor or upcycling workshop.',
      'If torn/stained beyond repair: it can still be recycled as rags.',
      'Place unwanted textiles in a sealed bag to keep them clean.',
      'Look for textile collection boxes at shopping centres or mosques.',
      'Do NOT put wet or mouldy textiles in donation bins.',
      'Drop off at a textile recycling bin or authorised collection point.',
    ],
    stepsUr: [
      'حالت جانچیں: کیا یہ پہننے یوگ ہے، قابل مرمت، یا بالکل ناقابل استعمال؟',
      'اگر پہننے یوگ ہے: دھوئیں، تہ کریں، اور کسی چیریٹی کو عطیہ کریں۔',
      'اگر قابل مرمت ہے: درزی یا اپ سائیکلنگ ورکشاپ لے جائیں۔',
      'اگر پھٹا/داغدار ہے: پھر بھی چیتھڑوں کے طور پر ری سائیکل ہو سکتا ہے۔',
      'بے کار کپڑے کو صاف رکھنے کے لیے بند بیگ میں ڈالیں۔',
      'شاپنگ سینٹر یا مساجد میں ٹیکسٹائل کلیکشن باکسز تلاش کریں۔',
      'عطیہ کے ڈبوں میں گیلے یا پھپھوندی لگے کپڑے نہ ڈالیں۔',
      'ٹیکسٹائل ری سائیکلنگ ڈبے یا مجاز کلیکشن پوائنٹ پر ڈراپ کریں۔',
    ],
    doList:    ['Donate wearable items', 'Bag textiles to keep clean', 'Check for local donation drives'],
    dontList:  ["Don't put wet textiles in bins", "Don't throw in general waste", "Don't mix with food waste"],
  ),

  'wood': DisposalGuidance(
    category:  'wood',
    tipEn:     'Repurpose if possible or take to a timber recycling facility.',
    tipUr:     'اگر ہو سکے تو دوبارہ استعمال کریں یا لکڑی ری سائیکلنگ مرکز پر لے جائیں۔',
    binColor:  'Brown',
    icon:      '🪵',
    steps: [
      'Check if the wood can be repurposed — e.g., shelves, planters, or firewood.',
      'Remove any metal nails, screws, or hardware from the wood.',
      'Remove paint, varnish, or treated coatings if required by your facility.',
      'Split large pieces into smaller sections for easier transport.',
      'Untreated wood can be composted if shredded into small chips.',
      'Treated or painted wood MUST go to a dedicated wood recycling facility.',
      'Do NOT burn treated or painted wood — it releases toxic fumes.',
      'Drop off at a timber recycling or waste transfer station.',
    ],
    stepsUr: [
      'چیک کریں کہ لکڑی دوبارہ استعمال ہو سکتی ہے — مثلاً شیلف، پلانٹر، یا جلانے کی لکڑی۔',
      'لکڑی سے دھاتی کیلیں، پیچ یا ہارڈویئر ہٹا دیں۔',
      'اگر آپ کی سہولت کی ضرورت ہو تو پینٹ، وارنش یا ٹریٹڈ کوٹنگ ہٹا دیں۔',
      'آسان نقل و حمل کے لیے بڑے ٹکڑوں کو چھوٹے حصوں میں تقسیم کریں۔',
      'بغیر ٹریٹمنٹ کی لکڑی کو چھوٹے چپس میں کاٹ کر کمپوسٹ کیا جا سکتا ہے۔',
      'ٹریٹڈ یا پینٹ کی لکڑی لازمی طور پر وقف لکڑی ری سائیکلنگ سہولت میں جانی چاہیے۔',
      'ٹریٹڈ یا پینٹ لکڑی نہ جلائیں — یہ زہریلا دھواں خارج کرتی ہے۔',
      'ٹمبر ری سائیکلنگ یا ویسٹ ٹرانسفر اسٹیشن پر ڈراپ کریں۔',
    ],
    doList:    ['Repurpose when possible', 'Remove metal hardware', 'Shred untreated wood for composting'],
    dontList:  ["Don't burn treated wood", "Don't mix with general waste", "Don't leave oversized wood on the street"],
  ),

  'food_waste': DisposalGuidance(
    category:  'food_waste',
    tipEn:     'Compost or dispose in the organic (green) bin.',
    tipUr:     'کمپوسٹ کریں یا نامیاتی (سبز) ڈبے میں ڈالیں۔',
    binColor:  'Green',
    icon:      '🌱',
    steps: [
      'Separate food waste from packaging immediately after eating or cooking.',
      'Collect food scraps in a small sealed container in your kitchen.',
      'Drain excess liquid from food waste before disposal.',
      "If composting at home: add to a compost bin with equal 'green' and 'brown' material.",
      'Do NOT add meat, fish, or dairy to a home compost bin.',
      'If using a council organic bin: tie scraps in a compostable bag.',
      'Keep the organic bin closed to prevent odours and pests.',
      'Empty the container into the green organic bin on collection day.',
    ],
    stepsUr: [
      'کھانے یا پکانے کے فوراً بعد کھانے کے فضلے کو پیکیجنگ سے الگ کریں۔',
      'کچن میں چھوٹے بند کنٹینر میں کھانے کے ٹکڑے جمع کریں۔',
      'ٹھکانے لگانے سے پہلے کھانے کے فضلے سے اضافی مائع نکالیں۔',
      "گھر پر کمپوسٹنگ: برابر 'سبز' اور 'بھورے' مواد کے ساتھ کمپوسٹ ڈبے میں شامل کریں۔",
      'گھریلو کمپوسٹ ڈبے میں گوشت، مچھلی یا ڈیری مت ڈالیں۔',
      'کونسل کا نامیاتی ڈبہ استعمال کرتے ہوئے: ٹکڑوں کو کمپوسٹ ایبل بیگ میں باندھیں۔',
      'بو اور کیڑوں سے بچنے کے لیے نامیاتی ڈبہ بند رکھیں۔',
      'کلیکشن کے دن سبز نامیاتی ڈبے میں خالی کریں۔',
    ],
    doList:    ['Compost fruit & vegetable scraps', 'Drain liquids first', 'Use compostable bags'],
    dontList:  ["Don't add meat/fish to home compost", "Don't leave bin open", "Don't mix with recyclables"],
  ),

  'not_food_waste': DisposalGuidance(
    category:  'not_food_waste',
    tipEn:     'Dispose in the general waste bin.',
    tipUr:     'عام کوڑے کے ڈبے میں ڈالیں۔',
    binColor:  'Black',
    icon:      '🗑️',
    steps: [
      'Confirm the item is not recyclable or compostable.',
      'If the item has multiple materials, check if parts can be separated and recycled.',
      'Bag the item in a sealed waste bag to prevent littering.',
      'Do NOT place loose, unbagged waste in public bins.',
      'Do NOT mix recyclables with general waste — it contaminates the batch.',
      'Check if your local area has a residual waste collection schedule.',
      'For bulky items: arrange a special collection or take to a waste transfer station.',
      'Place the sealed bag in the black general waste bin.',
    ],
    stepsUr: [
      'تصدیق کریں کہ آئٹم ری سائیکل یا کمپوسٹ کے قابل نہیں ہے۔',
      'اگر آئٹم میں متعدد مواد ہیں تو چیک کریں کہ آیا حصے الگ کر کے ری سائیکل ہو سکتے ہیں۔',
      'گندگی سے بچنے کے لیے آئٹم کو بند ویسٹ بیگ میں ڈالیں۔',
      'عوامی ڈبوں میں ڈھیلا، بے بیگ کچرا نہ ڈالیں۔',
      'ری سائیکل کرنے والے مواد کو عام کچرے سے نہ ملائیں — یہ پوری کھیپ کو خراب کرتا ہے۔',
      'چیک کریں کہ آیا آپ کے مقامی علاقے میں بقایا فضلہ اٹھانے کا شیڈول ہے۔',
      'بڑے آئٹمز کے لیے: خصوصی کلیکشن ترتیب دیں یا ویسٹ ٹرانسفر اسٹیشن لے جائیں۔',
      'بند بیگ سیاہ عام کچرے کے ڈبے میں ڈالیں۔',
    ],
    doList:    ['Bag waste securely', 'Separate any recyclable parts first', 'Use designated collection points'],
    dontList:  ["Don't mix recyclables with general waste", "Don't litter", "Don't dump bulky items illegally"],
  ),
};

/// Returns guidance for a category, falling back to the default.
DisposalGuidance getDisposalGuidance(String category) {
  final key = category.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  return kDisposalData[key] ?? kDisposalData[category.toLowerCase()] ?? _defaultGuidance;
}

/// Parses live guidance returned from the feedback API response.
DisposalGuidance guidanceFromJson(Map<String, dynamic> json) {
  return DisposalGuidance(
    category: json['waste_category'] ?? json['category'] ?? 'other',
    tipEn:    json['tip_english'] ?? json['tip_en'] ?? '',
    tipUr:    json['tip_urdu']   ?? json['tip_ur']  ?? '',
    binColor: json['bin_color']  ?? 'Black',
    icon:     json['icon']       ?? '🗑️',
    steps:    List<String>.from(json['steps']    ?? []),
    stepsUr:  List<String>.from(json['steps_ur'] ?? []),
    doList:   List<String>.from(json['do_list']  ?? []),
    dontList: List<String>.from(json['dont_list'] ?? []),
  );
}
