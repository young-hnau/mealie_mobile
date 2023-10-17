import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mealie_mobile/app/app_bloc.dart';
import 'package:mealie_repository/mealie_repository.dart';

part 'recipe_state.dart';

class RecipeCubit extends Cubit<RecipeState> {
  RecipeCubit({required this.appBloc, required Recipe recipe})
      : _recipe = recipe,
        super(const RecipeState(
          status: RecipeStatus.ready,
        )) {
    getRecipe();
  }

  final AppBloc appBloc;
  final Recipe _recipe;

  Future<void> getRecipe({int pageKey = 1, String? search}) async {
    try {
      Recipe? recipe;
      if (_recipe.slug != null) {
        emit(state.copyWith(status: RecipeStatus.loading));
        recipe = await appBloc.state.mealieRepository.getRecipe(
            token: appBloc.state.user.refreshToken, slug: _recipe.slug!);

        if (recipe == null) {
          throw Exception("An unknown error occuried while getting recipes");
        }
      }
      emit(state.copyWith(
        status: RecipeStatus.loaded,
        recipe: recipe ?? _recipe,
        editingRecipe: recipe ?? _recipe,
      ));
    } on Exception catch (err) {
      emit(state.copyWith(
          status: RecipeStatus.error, errorMessage: err.toString()));
    }
  }

  Future<void> checkIngredient(Ingredient ingredient) async {
    List<String>? checkedIngredients = state.checkedIngredients;
    checkedIngredients ??= [];

    if (checkedIngredients.contains(ingredient.referenceId)) {
      checkedIngredients
          .removeWhere((element) => element == ingredient.referenceId);
    } else if (ingredient.referenceId != null) {
      checkedIngredients.add(ingredient.referenceId!);
    }

    emit(state.copyWith(checkedIngredients: checkedIngredients));
  }

  Future<void> copyIngredientsToClipboard() async {
    await Clipboard.setData(ClipboardData(
        text:
            state.recipe!.recipeIngredient!.map((e) => e.display).join('\n')));
  }

  Future<void> setRating(int rating) async {
    await appBloc.state.mealieRepository.updateOneRecipe(
        token: appBloc.state.user.refreshToken,
        recipe: state.recipe!.copyWith(rating: rating));
    getRecipe();
  }

  void endEditing() {
    emit(state.copyWith(status: RecipeStatus.loaded));
  }

  void beginEditing() {
    emit(state.copyWith(
      status: RecipeStatus.editing,
      editingRecipe: Recipe.from(state.recipe),
    ));
  }

  Future<void> saveRecipe() async {
    await appBloc.state.mealieRepository.updateOneRecipe(
        token: appBloc.state.user.refreshToken, recipe: state.editingRecipe!);
    getRecipe();
  }

  void updateRecipe({
    String? name,
    String? recipeYield,
    String? totalTime,
    String? prepTime,
    String? cookTime,
    String? performTime,
    String? description,
  }) {
    if (state.editingRecipe == null) return;

    Recipe recipe = state.editingRecipe!;

    recipe = recipe.copyWith(
      name: name,
      recipeYield: recipeYield,
      totalTime: totalTime,
      prepTime: prepTime,
      cookTime: cookTime,
      performTime: performTime,
      description: description,
    );

    emit(state.copyWith(editingRecipe: recipe));
  }

  void updateIngredientNote(int index, String newValue) {
    if (state.editingRecipe == null) return;

    Recipe recipe = state.editingRecipe!;

    List<Ingredient>? ingredients = recipe.recipeIngredient;
    ingredients ??= [];

    Ingredient ingredient = ingredients.removeAt(index);
    ingredient = ingredient.copyWith(note: newValue);
    ingredients.insert(index, ingredient);

    recipe = recipe.copyWith(recipeIngredients: ingredients);

    emit(state.copyWith(editingRecipe: recipe));
  }

  void updateIngredientTitle(int index, String newValue) {
    if (state.editingRecipe == null) return;

    Recipe recipe = state.editingRecipe!;

    List<Ingredient>? ingredients = recipe.recipeIngredient;
    ingredients ??= [];

    Ingredient ingredient = ingredients.removeAt(index);
    ingredient = ingredient.copyWith(title: newValue);
    ingredients.insert(index, ingredient);

    recipe = recipe.copyWith(recipeIngredients: ingredients);

    emit(state.copyWith(editingRecipe: recipe));
  }

  void updateInstructionTitle(int index, String newValue) {
    if (state.editingRecipe == null) return;

    Recipe recipe = state.editingRecipe!;

    List<Instruction>? instructions = recipe.recipeInstructions;
    instructions ??= [];

    Instruction instruction = instructions.removeAt(index);
    instruction = instruction.copyWith(title: newValue);
    instructions.insert(index, instruction);

    recipe = recipe.copyWith(recipeInstructions: instructions);

    emit(state.copyWith(editingRecipe: recipe));
  }

  void reorderIngredients(int oldIndex, int newIndex) {
    if (state.editingRecipe == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    Recipe recipe = state.editingRecipe!;
    List<Ingredient>? ingredients = recipe.recipeIngredient;
    if (ingredients == null) return;

    final Ingredient ingredient = ingredients.removeAt(oldIndex);
    ingredients.insert(newIndex, ingredient);

    recipe = recipe.copyWith(recipeIngredients: ingredients);

    emit(state.copyWith(editingRecipe: recipe));
  }

  void reorderInstructions(int oldIndex, int newIndex) {
    if (state.editingRecipe == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    Recipe recipe = state.editingRecipe!;
    List<Instruction>? instructions = recipe.recipeInstructions;
    if (instructions == null) return;

    final Instruction instruction = instructions.removeAt(oldIndex);
    instructions.insert(newIndex, instruction);

    recipe = recipe.copyWith(recipeInstructions: instructions);

    emit(state.copyWith(editingRecipe: recipe));
  }

  void deleteIngredient(int index) {
    if (state.editingRecipe == null) return;

    Recipe recipe = state.editingRecipe!;
    List<Ingredient>? ingredients = recipe.recipeIngredient == null
        ? null
        : List<Ingredient>.from(recipe.recipeIngredient!);
    if (ingredients == null) return;

    ingredients.removeAt(index);

    recipe = recipe.copyWith(recipeIngredients: ingredients);

    emit(state.copyWith(editingRecipe: recipe));
  }

  void deleteInstruction(int index) {
    if (state.editingRecipe == null) return;

    Recipe recipe = state.editingRecipe!;
    List<Instruction>? instructions = recipe.recipeInstructions == null
        ? null
        : List<Instruction>.from(recipe.recipeInstructions!);
    if (instructions == null) return;

    instructions.removeAt(index);

    recipe = recipe.copyWith(recipeInstructions: instructions);

    emit(state.copyWith(editingRecipe: recipe));
  }

  void toggleIngredientSection(int index) {
    if (state.editingRecipe == null) return;
    Recipe recipe = state.editingRecipe!;
    List<Ingredient>? ingredients = recipe.recipeIngredient == null
        ? null
        : List<Ingredient>.from(recipe.recipeIngredient!);
    if (ingredients == null) return;

    Ingredient ingredient = ingredients.removeAt(index);
    String? title =
        ingredient.title == null || ingredient.title!.isEmpty ? " " : "";
    ingredient = ingredient.copyWith(title: title);
    ingredients.insert(index, ingredient);

    recipe = recipe.copyWith(recipeIngredients: ingredients);

    emit(state.copyWith(editingRecipe: recipe));
  }

  void toggleInstructionSection(int index) {
    if (state.editingRecipe == null) return;
    Recipe recipe = state.editingRecipe!;
    List<Instruction>? instructions = recipe.recipeInstructions == null
        ? null
        : List<Instruction>.from(recipe.recipeInstructions!);
    if (instructions == null) return;

    Instruction instruction = instructions.removeAt(index);
    String? title =
        instruction.title == null || instruction.title!.isEmpty ? " " : "";
    instruction = instruction.copyWith(title: title);
    instructions.insert(index, instruction);

    recipe = recipe.copyWith(recipeInstructions: instructions);

    emit(state.copyWith(editingRecipe: recipe));
  }
}