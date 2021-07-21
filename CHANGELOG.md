## [0.5.0] - 2021-07-20

- Initial release
- Alpha version
- Anyone who include this gem should consider reviewing the code
- Consider locking the version until stable
- Creation of
  * Generators
  * Serachable::Indexation, ActiveRecord rleation to Serachable::Index, and self.serach method
  * Searchable::Index, indexation of records as searchable
  * Searchbale::IndexWorker, async update of index
  * Searchable::QueryInterface
    + Sanitizers, accepting ad modifying params
    + Builder, producting SQL  queries
    + ControllerMethods, wrap sanitation anf building

## [0.5.01] - 2021-07-20

- Added searchable_indexation_inclusions on indexation for configuring method index_all_searchable

## [0.5.03] - 2021-07-20

- Added strippers array on indexation allowing configuration of called strippers per model. Now no compression is done by default.

## [0.5.04] - 2021-07-21

- Corrected mistake in indexation, index_all_searchable, includers
- Searchable::Index#touch_owner uses the class of the owner rather than type

## [0.5.05] - 2021-07-21

- limitation on searchable attribute corrected

## [0.5.06] - 2021-07-21

- Corrected sti behaviour in indexation, base_class name is always set in Searchable::Index

## [0.5.07] - 2021-07-21

- Corrected spelling mistake

## [0.5.08] - 2021-07-21

- Changed updated_at call in builder

## [0.5.09] - 2021-07-21

- Changed updated_at using rails default to ensure right time conversion and column naming
