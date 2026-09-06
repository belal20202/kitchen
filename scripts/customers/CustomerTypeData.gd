extends Resource
class_name CustomerTypeData
## Data-driven definition of a customer archetype. Actual per-customer
## runtime state lives in Customer.gd; this resource only holds the
## tunable parameters that differentiate each type.

enum CustomerType { NORMAL, PATIENT, IMPATIENT, VIP, FAMILY, RUSH }

@export var type_id: CustomerType = CustomerType.NORMAL
@export var display_name: String = "Normal"
@export var base_patience_seconds: float = 45.0
@export var patience_decay_multiplier: float = 1.0 # >1 = loses patience faster.
@export var tip_multiplier: float = 1.0 # Applied on top of EconomyManager tip calc.
@export var payment_multiplier: float = 1.0 # Applied to the recipe's base price.
@export var order_size: int = 1 # How many dishes this customer orders at once (Family = more).
@export var portrait: Texture2D
@export var portrait_path: String = "" # res:// path; loaded into `portrait` at runtime by LevelManager.
@export var spawn_weight: float = 1.0 # Relative likelihood of spawning, per level config.

static func create_default_types() -> Dictionary:
	# Convenience factory used by tests / fallback when .tres resources
	# are not present yet (e.g. during early development).
	var types := {}

	var normal := CustomerTypeData.new()
	normal.type_id = CustomerType.NORMAL
	normal.display_name = "Normal"
	normal.base_patience_seconds = 45.0
	types["normal"] = normal

	var patient := CustomerTypeData.new()
	patient.type_id = CustomerType.PATIENT
	patient.display_name = "Patient"
	patient.base_patience_seconds = 70.0
	patient.patience_decay_multiplier = 0.7
	patient.tip_multiplier = 1.1
	types["patient"] = patient

	var impatient := CustomerTypeData.new()
	impatient.type_id = CustomerType.IMPATIENT
	impatient.display_name = "Impatient"
	impatient.base_patience_seconds = 25.0
	impatient.patience_decay_multiplier = 1.5
	impatient.tip_multiplier = 0.9
	types["impatient"] = impatient

	var vip := CustomerTypeData.new()
	vip.type_id = CustomerType.VIP
	vip.display_name = "VIP"
	vip.base_patience_seconds = 40.0
	vip.tip_multiplier = 2.0
	vip.payment_multiplier = 1.5
	types["vip"] = vip

	var family := CustomerTypeData.new()
	family.type_id = CustomerType.FAMILY
	family.display_name = "Family"
	family.base_patience_seconds = 55.0
	family.order_size = 3
	family.payment_multiplier = 1.0
	types["family"] = family

	var rush := CustomerTypeData.new()
	rush.type_id = CustomerType.RUSH
	rush.display_name = "Rush Customer"
	rush.base_patience_seconds = 18.0
	rush.patience_decay_multiplier = 2.0
	rush.tip_multiplier = 1.3
	types["rush"] = rush

	return types
