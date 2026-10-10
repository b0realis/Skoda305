extends Node
## Localization (autoload "L"). Four languages, CP437-style: no diacritics
## anywhere (German umlauts become OE/UE, Slovene carons are dropped).
## Selection persists to user://settings.cfg.

const LANGS := ["en", "sl", "de", "it"]
const LANG_NAMES := {"en": "ENGLISH", "sl": "SLOVENSKO", "de": "DEUTSCH", "it": "ITALIANO"}
const CFG_PATH := "user://settings.cfg"

var cur := "sl"

const T := {
	"subtitle": {
		"sl": "MOZNAR 30.5CM M.11", "en": "30.5CM MORTAR M.11",
		"de": "30.5CM MOERSER M.11", "it": "OBICE 305MM M.11"},
	"title": {
		"sl": "SKODA 305", "en": "SKODA 305",
		"de": "SKODA 305", "it": "SKODA 305"},
	"subtitle2": {
		"sl": "SOSKA FRONTA 1915 - 1917", "en": "ISONZO FRONT 1915 - 1917",
		"de": "ISONZOFRONT 1915 - 1917", "it": "FRONTE ISONZO 1915 - 1917"},
	"menu_1p": {
		"sl": "1 IGRALEC", "en": "1 PLAYER",
		"de": "1 SPIELER", "it": "1 GIOCATORE"},
	"menu_2p": {
		"sl": "2 IGRALCA", "en": "2 PLAYERS",
		"de": "2 SPIELER", "it": "2 GIOCATORI"},
	"lang_label": {
		"sl": "JEZIK", "en": "LANGUAGE", "de": "SPRACHE", "it": "LINGUA"},
	"menu_help": {
		"sl": "SOLA", "en": "SCHOOL", "de": "SCHULE", "it": "SCUOLA"},
	"btn_fire": {
		"sl": "OGENJ", "en": "FIRE", "de": "FEUER", "it": "FUOCO"},
	"btn_menu": {
		"sl": "MENI", "en": "MENU", "de": "MENUE", "it": "MENU"},
	"btn_hold_wind": {
		"sl": "DRZI: VETER", "en": "HOLD: WIND",
		"de": "HALTEN: WIND", "it": "TIENI: VENTO"},
	"scale_label": {
		"sl": "SLIKA", "en": "PICTURE", "de": "BILD", "it": "IMMAGINE"},
	"lbl_weapon": {
		"sl": "OROZJE", "en": "WEAPON", "de": "WAFFE", "it": "ARMA"},
	"scale_sharp": {
		"sl": "OSTRA", "en": "SHARP", "de": "SCHARF", "it": "NITIDA"},
	"scale_full_v": {
		"sl": "POLNA", "en": "FULL", "de": "VOLL", "it": "PIENA"},
	"touch_title": {
		"sl": "UPRAVLJANJE NA DOTIK", "en": "TOUCH CONTROLS",
		"de": "TOUCH-STEUERUNG", "it": "CONTROLLI TOUCH"},
	"touch_l1": {
		"sl": "DRZI GUMBE: < > KOT, + - MOC (S PONAVLJANJEM)",
		"en": "HOLD BUTTONS: < > ANGLE, + - POWER (AUTO-REPEAT)",
		"de": "GEDRUECKT HALTEN: < > WINKEL, + - KRAFT",
		"it": "TIENI PREMUTO: < > ANGOLO, + - POTENZA (RIPETE)"},
	"touch_l2": {
		"sl": "OROZJE: DOTIK = MENJAVA, DRZI = VETRNA ZASTAVICA",
		"en": "WEAPON: TAP = CYCLE, HOLD = WIND FLAG",
		"de": "WAFFE: TIPPEN = WECHSEL, HALTEN = WINDFLAGGE",
		"it": "ARMA: TOCCO = CAMBIO, TIENI = BANDIERA DEL VENTO"},
	"touch_l3": {
		"sl": "MENI: PRVI DOTIK IZBERE, DRUGI POTRDI",
		"en": "MENU: FIRST TAP SELECTS, SECOND CONFIRMS",
		"de": "MENUE: ERSTES TIPPEN WAEHLT, ZWEITES BESTAETIGT",
		"it": "MENU: PRIMO TOCCO SCEGLIE, SECONDO CONFERMA"},
	"touch_l4": {
		"sl": "SOLA: LEVI ROB = NAZAJ, DRUGJE = NAPREJ",
		"en": "SOLA: LEFT EDGE = BACK, ANYWHERE ELSE = FORWARD",
		"de": "SOLA: LINKER RAND = ZURUECK, SONST = WEITER",
		"it": "SOLA: BORDO SINISTRO = INDIETRO, ALTROVE = AVANTI"},
	"touch_l5": {
		"sl": "SLIKA (OSTRA/POLNA): TIPKA S ALI DOTIK NA NASLOVNICI",
		"en": "PICTURE (SHARP/FULL): KEY S OR TAP ON THE TITLE",
		"de": "BILD (SCHARF/VOLL): TASTE S ODER AM TITEL TIPPEN",
		"it": "IMMAGINE (NITIDA/PIENA): TASTO S O TOCCO SUL TITOLO"},
	"assist_hint": {
		"sl": "POMOC (TIPKA P)", "en": "ASSIST (KEY P)",
		"de": "HILFE (TASTE P)", "it": "AIUTO (TASTO P)"},
	"hard_hint": {
		"sl": "TEZKO (TIPKA H)", "en": "HARD (KEY H)",
		"de": "SCHWER (TASTE H)", "it": "DIFFICILE (TASTO H)"},
	"hard_on": {
		"sl": "TEZKO: ZGODOVINSKE POLNITVE 1-5",
		"en": "HARD: HISTORICAL CHARGES 1-5",
		"de": "SCHWER: HISTORISCHE LADUNGEN 1-5",
		"it": "DIFFICILE: CARICHE STORICHE 1-5"},
	"charge": {
		"sl": "POLNITEV", "en": "CHARGE", "de": "LADUNG", "it": "CARICA"},
	"st_charges": {
		"sl": "POLNITVE", "en": "CHARGES", "de": "LADUNGEN", "it": "CARICHE"},
	"st_powder": {
		"sl": "SMODNIK", "en": "POWDER", "de": "PULVER", "it": "POLVERE"},
	"hard_title": {
		"sl": "TEZKO: SMODNIK IN POLNITVE",
		"en": "HARD: POWDER AND CHARGES",
		"de": "SCHWER: PULVER UND LADUNGEN",
		"it": "DIFFICILE: POLVERE E CARICHE"},
	"hard_h1": {
		"sl": "M.11: BREZDIMNI SMODNIK RINGPULVER M.97",
		"en": "M.11: RINGPULVER M.97 SMOKELESS POWDER",
		"de": "M.11: RAUCHLOSES RINGPULVER M.97",
		"it": "M.11: POLVERE INFUME RINGPULVER M.97"},
	"hard_h2": {
		"sl": "STOPENJSKE POLNITVE 1-4, PETA ZA LAZJE GRANATE",
		"en": "INCREMENTAL CHARGES 1-4, A FIFTH FOR LIGHTER SHELLS",
		"de": "STUFENLADUNGEN 1-4, FUENFTE FUER LEICHTE GRANATEN",
		"it": "CARICHE 1-4, LA QUINTA PER GRANATE LEGGERE"},
	"hard_h3": {
		"sl": "GRANATI: 380 KG TEZKA, 287 KG LAHKA (TRUPPENGRANATE)",
		"en": "SHELLS: 380 KG HEAVY, 287 KG LIGHT (TRUPPENGRANATE)",
		"de": "GRANATEN: 380 KG SCHWER, 287 KG LEICHT",
		"it": "GRANATE: 380 KG PESANTE, 287 KG LEGGERA"},
	"hard_h4": {
		"sl": "V0 DO 330-340 M/S, DOSEG 9.6-11 KM (PO RAZLICICI)",
		"en": "V0 UP TO 330-340 M/S, RANGE 9.6-11 KM BY VARIANT",
		"de": "V0 BIS 330-340 M/S, REICHWEITE 9.6-11 KM",
		"it": "V0 FINO A 330-340 M/S, GITTATA 9.6-11 KM"},
	"hard_h5": {
		"sl": "V TEZKEM: MOC LE V 5 POLNITVAH - CILJAJ S KOTOM!",
		"en": "IN HARD MODE: POWER IN 5 CHARGES ONLY - LAY WITH ANGLE!",
		"de": "IM SCHWEREN MODUS: NUR 5 LADUNGEN - MIT WINKEL RICHTEN!",
		"it": "IN DIFFICILE: SOLO 5 CARICHE - PUNTA CON L'ANGOLO!"},
	"hard_h6": {
		"sl": "380KG GRANATA: NAJVEC 4. POLNITEV",
		"en": "THE 380KG SHELL TAKES AT MOST CHARGE 4",
		"de": "380KG-GRANATE: HOECHSTENS 4. LADUNG",
		"it": "GRANATA 380KG: MASSIMO CARICA 4"},
	"assist_on": {
		"sl": "POMOC: NAPREDNI BALISTICNI KALKULATOR",
		"en": "ASSIST: ADVANCED BALLISTIC CALCULATOR",
		"de": "HILFE: ERWEITERTER BALLISTIKRECHNER",
		"it": "AIUTO: CALCOLATORE BALISTICO AVANZATO"},
	"calc_title": {
		"sl": "KALKULATOR", "en": "CALCULATOR",
		"de": "RECHNER", "it": "CALCOLATORE"},
	"calc_aim": {
		"sl": "CILJAJ", "en": "AIM", "de": "ZIELE", "it": "MIRA"},
	"calc_pred": {
		"sl": "NAPOVED", "en": "PREDICTED", "de": "PROGNOSE", "it": "PREVISTO"},
	"calc_meas": {
		"sl": "MERITEV", "en": "MEASURED", "de": "MESSUNG", "it": "MISURATO"},
	"help_title": {
		"sl": "PRIROCNIK: VETER IN BALISTIKA",
		"en": "MANUAL: WIND AND BALLISTICS",
		"de": "HANDBUCH: WIND UND BALLISTIK",
		"it": "MANUALE: VENTO E BALISTICA"},
	"help_nowind": {
		"sl": "BREZ VETRA", "en": "NO WIND", "de": "OHNE WIND", "it": "SENZA VENTO"},
	"help_wind": {
		"sl": "VETER W=8", "en": "WIND W=8", "de": "WIND W=8", "it": "VENTO W=8"},
	"help_drift": {
		"sl": "ZANOS", "en": "DRIFT", "de": "ABDRIFT", "it": "DERIVA"},
	"help_w1": {
		"sl": "VETER POTISKA GRANATO VODORAVNO VES CAS LETA.",
		"en": "WIND PUSHES THE SHELL SIDEWAYS FOR THE WHOLE FLIGHT.",
		"de": "DER WIND SCHIEBT DIE GRANATE DEN GANZEN FLUG LANG.",
		"it": "IL VENTO SPINGE LA GRANATA PER TUTTO IL VOLO."},
	"help_w2": {
		"sl": "ZANOS RASTE S KVADRATOM CASA: VISOK LOK = VELIK ZANOS.",
		"en": "DRIFT GROWS WITH TIME SQUARED: HIGH ARC = BIG DRIFT.",
		"de": "ABDRIFT WAECHST MIT T IM QUADRAT: HOHER BOGEN = MEHR.",
		"it": "LA DERIVA CRESCE COL QUADRATO DEL TEMPO: ARCO ALTO = TANTA."},
	"help_nav": {
		"sl": "LEVO/DESNO: LISTAJ   ESC: NAZAJ",
		"en": "LEFT/RIGHT: PAGES   ESC: BACK",
		"de": "LINKS/RECHTS: SEITEN   ESC: ZURUECK",
		"it": "SIN/DES: PAGINE   ESC: INDIETRO"},
	"st_caliber": {"sl": "KALIBER", "en": "CALIBER", "de": "KALIBER", "it": "CALIBRO"},
	"st_weight": {"sl": "TEZA", "en": "WEIGHT", "de": "GEWICHT", "it": "PESO"},
	"st_shell": {"sl": "GRANATA", "en": "SHELL", "de": "GRANATE", "it": "GRANATA"},
	"st_range": {"sl": "DOSEG", "en": "RANGE", "de": "REICHWEITE", "it": "GITTATA"},
	"st_elev": {"sl": "ELEVACIJA", "en": "ELEVATION", "de": "ELEVATION", "it": "ELEVAZIONE"},
	"st_rate": {"sl": "STRELJANJE", "en": "FIRE RATE", "de": "FEUERRATE", "it": "CADENZA"},
	"st_crew": {"sl": "POSADKA", "en": "CREW", "de": "BEDIENUNG", "it": "SERVENTI"},
	"st_service": {"sl": "V UPORABI", "en": "IN SERVICE", "de": "IM DIENST", "it": "IN SERVIZIO"},
	"flag_title": {
		"sl": "POMOCNIK: ZASTAVICA (DRZI TAB)",
		"en": "HELPER: THE FLAG (HOLD TAB)",
		"de": "HELFER: FLAGGE (TAB HALTEN)",
		"it": "AIUTO: LA BANDIERA (TIENI TAB)"},
	"flag_l1": {
		"sl": "DRZI TAB MED CILJANJEM: ZASTAVICA IN VOJAKOVA OCENA",
		"en": "HOLD TAB WHILE AIMING: THE FLAG AND THE SOLDIER'S CALL",
		"de": "TAB HALTEN BEIM ZIELEN: FLAGGE UND SOLDATEN-MELDUNG",
		"it": "TIENI TAB MENTRE MIRI: BANDIERA E STIMA DEL SOLDATO"},
	"flag_l2": {
		"sl": "MOCNEJSI VETER = BOLJ VODORAVNA IN HITREJE PLAPOLA",
		"en": "STRONGER WIND = MORE HORIZONTAL, FASTER FLUTTER",
		"de": "STAERKERER WIND = WAAGRECHTER, SCHNELLERES FLATTERN",
		"it": "VENTO PIU FORTE = PIU ORIZZONTALE, SVENTOLIO VELOCE"},
	"flag_l3": {
		"sl": "ENOTA VETRA (HUD) X 3 = PRIBL. VOZLI. W 9 = PRIBL. 27 VOZLOV",
		"en": "1 WIND UNIT (HUD) X 3 = ABOUT KNOTS. W 9 = ABOUT 27 KNOTS",
		"de": "WINDEINHEIT (HUD) X 3 = CA. KNOTEN. W 9 = CA. 27 KNOTEN",
		"it": "UNITA (HUD) X 3 = CIRCA NODI. W 9 = CIRCA 27 NODI"},
	"flag_l4": {
		"sl": "HUD STEVILKA JE TOCNA, VOJAKOVI VOZLI SO OCENA",
		"en": "THE HUD NUMBER IS EXACT, THE SOLDIER'S KNOTS ARE A GUESS",
		"de": "DIE HUD-ZAHL IST GENAU, DIE KNOTEN NUR GESCHAETZT",
		"it": "IL NUMERO HUD E ESATTO, I NODI SONO UNA STIMA"},
	"cap_skoda": {
		"sl": "V STRELNEM POLOZAJU", "en": "IN FIRING POSITION",
		"de": "IN FEUERSTELLUNG", "it": "IN POSIZIONE DI TIRO"},
	"cap_obice": {
		"sl": "KARNIJA: OGENJ NA MALBORGHETTO",
		"en": "CARNIA: FIRING ON MALBORGHETTO",
		"de": "KARNIEN: FEUER AUF MALBORGHETTO",
		"it": "CARNIA: FUOCO SU MALBORGHETTO"},
	"help_w3": {
		"sl": "1 ENOTA VETRA = PRIBL. 3 VOZLI. VOJAKOVA OCENA NI TOCNA.",
		"en": "1 WIND UNIT = ABOUT 3 KNOTS. THE SOLDIER'S GUESS IS ROUGH.",
		"de": "1 WINDEINHEIT = CA. 3 KNOTEN. DIE SCHAETZUNG IST GROB.",
		"it": "1 UNITA DI VENTO = CIRCA 3 NODI. LA STIMA E APPROSSIMATIVA."},
	"esc_quit": {
		"sl": "ESC = IZHOD", "en": "ESC = QUIT",
		"de": "ESC = ENDE", "it": "ESC = ESCI"},
	"controls1": {
		"sl": "KOT: LEVO/DESNO  MOC: GOR/DOL  SHIFT: FINO",
		"en": "ANGLE: LEFT/RIGHT  POWER: UP/DOWN  SHIFT: FINE",
		"de": "WINKEL: LINKS/RECHTS  KRAFT: AUF/AB  SHIFT: FEIN",
		"it": "ANGOLO: SIN/DES  POTENZA: SU/GIU  SHIFT: FINE"},
	"controls2": {
		"sl": "TAB: OROZJE (DRZI: VETER)  PRESLEDNICA: OGENJ",
		"en": "TAB: WEAPON (HOLD: WIND)  SPACE: FIRE",
		"de": "TAB: WAFFE (HALTEN: WIND)  LEER: FEUER",
		"it": "TAB: ARMA (TIENI: VENTO)  SPAZIO: FUOCO"},
	"soldier": {
		"sl": "VOJAK: %s Z MOCJO %d, KAR JE PRIBL. %d VOZLOV",
		"en": "SOLDIER: %s AT STRENGTH %d, ABOUT %d KNOTS",
		"de": "SOLDAT: %s MIT STAERKE %d, CA. %d KNOTEN",
		"it": "IL SOLDATO: %s CON FORZA %d, CIRCA %d NODI"},
	"soldier0": {
		"sl": "VOJAK: %s",
		"en": "SOLDIER: %s",
		"de": "SOLDAT: %s",
		"it": "IL SOLDATO: %s"},
	"wind_l": {
		"sl": "VETER Z LEVE", "en": "WIND FROM THE LEFT",
		"de": "WIND VON LINKS", "it": "VENTO DA SINISTRA"},
	"wind_r": {
		"sl": "VETER Z DESNE", "en": "WIND FROM THE RIGHT",
		"de": "WIND VON RECHTS", "it": "VENTO DA DESTRA"},
	"wind_0": {
		"sl": "BREZVETRJE", "en": "DEAD CALM",
		"de": "WINDSTILLE", "it": "CALMA PIATTA"},
	"angle": {"sl": "KOT", "en": "ANGLE", "de": "WINKEL", "it": "ANGOLO"},
	"power": {"sl": "MOC", "en": "POWER", "de": "KRAFT", "it": "POTENZA"},
	"wind": {"sl": "VETER", "en": "WIND", "de": "WIND", "it": "VENTO"},
	"round": {"sl": "RUNDA", "en": "ROUND", "de": "RUNDE", "it": "TURNO"},
	"team0": {"sl": "A-OGRSKA", "en": "AUSTRIA", "de": "OE-UNGARN", "it": "AUSTRIA"},
	"team1": {"sl": "ITALIJA", "en": "ITALY", "de": "ITALIEN", "it": "ITALIA"},
	"w0": {"sl": "GRANATA", "en": "SHELL", "de": "GRANATE", "it": "GRANATA"},
	"w1": {"sl": "380KG", "en": "380KG", "de": "380KG", "it": "380KG"},
	"w2": {"sl": "SRAPNEL", "en": "SHRAPNEL", "de": "SCHRAPNELL", "it": "SHRAPNEL"},
	"wins_round": {
		"sl": "%s OSVOJI RUNDO", "en": "%s WINS THE ROUND",
		"de": "%s GEWINNT DIE RUNDE", "it": "%s VINCE IL TURNO"},
	"draw_r": {
		"sl": "NEODLOCENO!", "en": "DRAW!",
		"de": "UNENTSCHIEDEN!", "it": "PAREGGIO!"},
	"press_key": {
		"sl": "PRITISNI TIPKO", "en": "PRESS ANY KEY",
		"de": "TASTE DRUECKEN", "it": "PREMI UN TASTO"},
	"wins_war": {
		"sl": "* ZMAGA V VOJNI! *", "en": "* WINS THE WAR! *",
		"de": "* SIEG IM KRIEG! *", "it": "* VINCE LA GUERRA! *"},
	"victor": {
		"sl": "ZMAGOVALEC: %s", "en": "VICTOR: %s",
		"de": "SIEGER: %s", "it": "VINCITORE: %s"},
	"presents": {
		"sl": "PREDSTAVLJA", "en": "PRESENTS",
		"de": "PRAESENTIERT", "it": "PRESENTA"},
	"photo_cap": {
		"sl": "SKODA 305MM NA POLOZAJU, 1916", "en": "SKODA 305MM IN POSITION, 1916",
		"de": "SKODA 305MM IN STELLUNG, 1916", "it": "SKODA 305MM IN POSIZIONE, 1916"},
	# controller variants: L.t() picks "<key>_pad" while Pad.active, so a
	# player holding a gamepad reads button names instead of keyboard keys
	"controls1_pad": {
		"sl": "KOT: LEVO/DESNO  MOC: GOR/DOL  LB/RB: FINO",
		"en": "ANGLE: LEFT/RIGHT  POWER: UP/DOWN  LB/RB: FINE",
		"de": "WINKEL: LINKS/RECHTS  KRAFT: AUF/AB  LB/RB: FEIN",
		"it": "ANGOLO: SIN/DES  POTENZA: SU/GIU  LB/RB: FINE"},
	"controls2_pad": {
		"sl": "X: OROZJE (DRZI: VETER)  A: OGENJ  START: MENI",
		"en": "X: WEAPON (HOLD: WIND)  A: FIRE  START: MENU",
		"de": "X: WAFFE (HALTEN: WIND)  A: FEUER  START: MENUE",
		"it": "X: ARMA (TIENI: VENTO)  A: FUOCO  START: MENU"},
	"assist_hint_pad": {
		"sl": "POMOC (GUMB Y)", "en": "ASSIST (BUTTON Y)",
		"de": "HILFE (KNOPF Y)", "it": "AIUTO (TASTO Y)"},
	"hard_hint_pad": {
		"sl": "TEZKO (GUMB X)", "en": "HARD (BUTTON X)",
		"de": "SCHWER (KNOPF X)", "it": "DIFFICILE (TASTO X)"},
	"help_nav_pad": {
		"sl": "LEVO/DESNO: LISTAJ   B: NAZAJ",
		"en": "LEFT/RIGHT: PAGES   B: BACK",
		"de": "LINKS/RECHTS: SEITEN   B: ZURUECK",
		"it": "SIN/DES: PAGINE   B: INDIETRO"},
	"press_key_pad": {
		"sl": "PRITISNI A", "en": "PRESS A",
		"de": "A DRUECKEN", "it": "PREMI A"},
	"flag_title_pad": {
		"sl": "POMOCNIK: ZASTAVICA (DRZI X)",
		"en": "HELPER: THE FLAG (HOLD X)",
		"de": "HELFER: FLAGGE (X HALTEN)",
		"it": "AIUTO: LA BANDIERA (TIENI X)"},
	"flag_l1_pad": {
		"sl": "DRZI X MED CILJANJEM: ZASTAVICA IN VOJAKOVA OCENA",
		"en": "HOLD X WHILE AIMING: THE FLAG AND THE SOLDIER'S CALL",
		"de": "X HALTEN BEIM ZIELEN: FLAGGE UND SOLDATEN-MELDUNG",
		"it": "TIENI X MENTRE MIRI: BANDIERA E STIMA DEL SOLDATO"},
	"scale_key": {"sl": "S", "en": "S", "de": "S", "it": "S"},
	"scale_key_pad": {"sl": "SELECT", "en": "SELECT", "de": "SELECT", "it": "SELECT"},
}


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		var saved = cfg.get_value("game", "lang", "sl")
		if saved is String and saved in LANGS:
			cur = saved


func t(key: String) -> String:
	if Pad.active and T.has(key + "_pad"):
		key += "_pad"
	var d: Dictionary = T.get(key, {})
	return d.get(cur, d.get("en", key))


func set_lang(lang: String) -> void:
	if not lang in LANGS:
		return
	cur = lang
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)
	cfg.set_value("game", "lang", cur)
	cfg.save(CFG_PATH)


func cycle(dirn: int) -> void:
	var i := LANGS.find(cur)
	set_lang(LANGS[(i + dirn + LANGS.size()) % LANGS.size()])
