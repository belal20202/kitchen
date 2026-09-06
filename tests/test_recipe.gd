extends TestCase
## Tests for recipe data loading via LevelManager and RecipeData behavior.

func test_recipes_loaded_from_json() -> void:
	var burger := LevelManager.get_recipe("burger")
	assert_true(burger != null, "burger recipe should exist")
	assert_eq(burger.recipe_name, "Burger", "burger recipe should have the correct name")
	assert_true(burger.ingredients.size() > 0, "burger recipe should have ingredients")

func test_recipe_total_time() -> void:
	var recipe := RecipeData.new()
	recipe.preparation_time = 3.0
	recipe.cooking_time = 8.0
	assert_almost_eq(recipe.get_total_time(), 11.0, 0.001, "total time should be prep + cook time")

func test_unknown_recipe_returns_null() -> void:
	var missing := LevelManager.get_recipe("does_not_exist")
	assert_true(missing == null, "unknown recipe id should return null")
