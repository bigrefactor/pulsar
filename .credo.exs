# Credo configuration for Pulsar component library
# Strict mode enabled with library-specific customizations
%{
  configs: [
    %{
      name: "default",
      files: %{
        excluded: [
          ~r"/_build/",
          ~r"/deps/",
          ~r"/node_modules/",
          "test/support/fixtures/"
        ],
        included: [
          "lib/",
          "test/"
        ]
      },
      plugins: [],
      requires: [],
      strict: true,
      parse_timeout: 5000,
      color: true,
      checks: %{
        enabled: [
          ## Consistency Checks
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.ParameterPatternMatching, []},
          {Credo.Check.Consistency.SpaceAroundOperators, []},
          {Credo.Check.Consistency.SpaceInParentheses, []},
          {Credo.Check.Consistency.TabsOrSpaces, []},

          ## Design Checks
          {Credo.Check.Design.AliasUsage,
           [
             priority: :high,
             if_nested_deeper_than: 2,
             if_called_more_often_than: 0
           ]},
          {Credo.Check.Design.TagFIXME, []},
          {Credo.Check.Design.TagTODO, [exit_status: 0]},

          ## Readability Checks
          {Credo.Check.Readability.AliasOrder, [priority: :high]},
          {Credo.Check.Readability.FunctionNames, []},
          {Credo.Check.Readability.LargeNumbers, []},
          {Credo.Check.Readability.MaxLineLength,
           [
             priority: :low,
             max_length: 120
           ]},
          {Credo.Check.Readability.ModuleAttributeNames, []},
          {Credo.Check.Readability.ModuleDoc,
           [
             ignore_names: [
               ~r/\.Test$/,
               ~r/Test\./,
               ~r/\.(DataCase|ConnCase|ComponentCase)$/,
               ~r/TestHelpers/,
               ~r/Support\./,
               ~r/Fixtures\./,
               # Generator tasks set @moduledoc via the `use Pulsar.Generator` macro;
               # Credo's static analysis can't see the macro injection.
               ~r/^Mix\.Tasks\.Pulsar\.Gen\./
             ]
           ]},
          {Credo.Check.Readability.ModuleNames, []},
          {Credo.Check.Readability.ParenthesesInCondition, []},
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, []},
          {Credo.Check.Readability.PipeIntoAnonymousFunctions, []},
          {Credo.Check.Readability.PredicateFunctionNames, []},
          {Credo.Check.Readability.PreferImplicitTry, []},
          {Credo.Check.Readability.RedundantBlankLines, []},
          {Credo.Check.Readability.Semicolons, []},
          {Credo.Check.Readability.SpaceAfterCommas, []},
          {Credo.Check.Readability.StringSigils, []},
          {Credo.Check.Readability.TrailingBlankLine, []},
          {Credo.Check.Readability.TrailingWhiteSpace, []},
          {Credo.Check.Readability.UnnecessaryAliasExpansion, []},
          {Credo.Check.Readability.VariableNames, []},
          {Credo.Check.Readability.WithSingleClause, []},

          ## Multi-alias enforcement - STRICT: separate lines only
          {Credo.Check.Readability.MultiAlias,
           [
             priority: :high
           ]},

          ## Refactoring Opportunities
          {Credo.Check.Refactor.Apply, []},
          {Credo.Check.Refactor.CondStatements, []},
          {Credo.Check.Refactor.CyclomaticComplexity,
           [
             max_complexity: 9
           ]},
          {Credo.Check.Refactor.FunctionArity,
           [
             max_arity: 8
           ]},
          {Credo.Check.Refactor.LongQuoteBlocks,
           [
             max_line_count: 100
           ]},
          {Credo.Check.Refactor.MatchInCondition, []},
          {Credo.Check.Refactor.NegatedConditionsInUnless, []},
          {Credo.Check.Refactor.NegatedConditionsWithElse, []},
          {Credo.Check.Refactor.Nesting,
           [
             max_nesting: 2
           ]},
          {Credo.Check.Refactor.UnlessWithElse, []},
          {Credo.Check.Refactor.WithClauses, []},

          ## Warnings
          {Credo.Check.Warning.ApplicationConfigInModuleAttribute, []},
          {Credo.Check.Warning.BoolOperationOnSameValues, []},
          {Credo.Check.Warning.Dbg, []},
          {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
          {Credo.Check.Warning.IExPry, []},
          {Credo.Check.Warning.IoInspect, []},
          {Credo.Check.Warning.MixEnv, []},
          {Credo.Check.Warning.OperationOnSameValues, []},
          {Credo.Check.Warning.OperationWithConstantResult, []},
          {Credo.Check.Warning.RaiseInsideRescue, []},
          {Credo.Check.Warning.SpecWithStruct, []},
          {Credo.Check.Warning.WrongTestFileExtension, []},
          {Credo.Check.Warning.UnusedEnumOperation, []},
          {Credo.Check.Warning.UnusedFileOperation, []},
          {Credo.Check.Warning.UnusedKeywordOperation, []},
          {Credo.Check.Warning.UnusedListOperation, []},
          {Credo.Check.Warning.UnusedPathOperation, []},
          {Credo.Check.Warning.UnusedRegexOperation, []},
          {Credo.Check.Warning.UnusedStringOperation, []},
          {Credo.Check.Warning.UnusedTupleOperation, []}
        ],
        disabled: [
          # Disabled for Phoenix LiveView components that use assigns pattern
          {Credo.Check.Readability.Specs, []},

          # Disabled because it's overly strict for component libraries
          {Credo.Check.Design.DuplicatedCode, []},

          # Disabled because Phoenix.Component uses them extensively
          {Credo.Check.Readability.StrictModuleLayout, []},

          # Disabled due to Elixir version incompatibility (requires < 1.8.0)
          {Credo.Check.Refactor.MapInto, []},

          # Disabled due to Elixir version incompatibility (requires < 1.7.0)
          {Credo.Check.Warning.LazyLogging, []}
        ]
      }
    }
  ]
}
