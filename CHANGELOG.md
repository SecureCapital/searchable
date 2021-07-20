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
