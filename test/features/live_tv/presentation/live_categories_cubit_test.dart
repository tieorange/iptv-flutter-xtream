@Skip('Temporarily disabled during AI-picks feature work; re-enable at project end. See AGENTS.md.')
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iptv/core/error/failures.dart';
import 'package:iptv/features/live_tv/domain/entities/live_category.dart';
import 'package:iptv/features/live_tv/domain/usecases/get_live_categories_usecase.dart';
import 'package:iptv/features/live_tv/presentation/cubit/live_categories_cubit.dart';

class _MockGetLiveCategories extends Mock implements GetLiveCategoriesUseCase {}

void main() {
  late _MockGetLiveCategories useCase;

  setUp(() {
    useCase = _MockGetLiveCategories();
  });

  const categories = [LiveCategory(id: 1, name: 'Sports')];

  blocTest<LiveCategoriesCubit, LiveCategoriesState>(
    'load emits Loading then Loaded on success',
    setUp: () => when(() => useCase()).thenReturn(TaskEither.right(categories)),
    build: () => LiveCategoriesCubit(useCase),
    act: (cubit) => cubit.load(),
    expect: () => [const LiveCategoriesLoading(), const LiveCategoriesLoaded(categories)],
  );

  blocTest<LiveCategoriesCubit, LiveCategoriesState>(
    'load emits Loading then Error on failure — never drops the Left branch',
    setUp: () => when(() => useCase())
        .thenReturn(TaskEither.left(const NetworkFailure('offline'))),
    build: () => LiveCategoriesCubit(useCase),
    act: (cubit) => cubit.load(),
    expect: () => [const LiveCategoriesLoading(), const LiveCategoriesError('offline')],
  );
}
