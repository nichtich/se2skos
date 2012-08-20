This repository includes tags and tag descriptions from StackExchange sites
converted to knowledge organization systems in SKOS format.

## Tags in StackExchange

[StackExchange](http://stackexchange.com) is a network of Questions & Answers
websites. Questions in each website are collaboratively [indexed by social
tagging in a set-model](http://arxiv.org/abs/cs/0701072) (each question is
assigned a set of tags that users of the community can edit). [StackExchange
tags](http://blog.stackoverflow.com/2010/08/tag-folksonomy-and-tag-synonyms/)
can be described with a short excerpt, a more detailed text, and they may have
synonyms. Tags can be edited by the community. The content of all StackExhange
websites, including tags and tag descriptions is licensed under CC-BY-SA.

## Repository outline

    data/                     - downloaded and transformed tagging data

	download-tags.pl          - script to download tags
	convert-tags.pl           - transform downloaded tags to SKOS
	graph-tags.pl			  - create a graph of the SKOS thesaurus

    lib/StackExchange/API.pm  - tiny wrapper of StackExchange API

## From Tags to SKOS

Although Jeff Atwood was [against hierarchical links between
tags](http://blog.stackoverflow.com/2010/08/tag-folksonomy-and-tag-synonyms/#comment-48892),
these relations are supported if given in a tag wiki with Unicode
upwards/downwards arrows (↑/↓). Mappings to other knowledge organization
systems are also added.

## Example

![sample graph from libraries.stackexchange.com](sample-graph.png)
