[StackExchange](http://stackexchange.com) is a network of Questions & Answers
websites. Questions in each website are collaboratively [indexed by social
tagging in a set-model](http://arxiv.org/abs/cs/0701072) (each question is
assigned a set of tags that users of the community can edit). [StackExchange
tags](http://blog.stackoverflow.com/2010/08/tag-folksonomy-and-tag-synonyms/)
can be described with a short excerpt, a more detailed text, and they may have
synonyms. Tags can be edited by the community. The content of all StackExhange
websites, including tags and tag descriptions is licensed under CC-BY-SA.

This repository includes scripts to dowload tags and tag descriptions from a
StackExchange website and to convert them to SKOS format. The program consists
of multiple scripts:

	download-tags.pl
	convert-tags.pl
    lib/StackExchange/API.pm

Although Jeff Atwood was [against hierarchical links between
tags](http://blog.stackoverflow.com/2010/08/tag-folksonomy-and-tag-synonyms/#comment-48892),
these relations are supported if given in a tag wiki with Unicode
upwards/downwards arrows (↑/↓). Mappings to other knowledge organization
systems will also be added later.

The scripts require the experimental Perl module SKOS::Simple, which is
included as git submodule. You may install SKOS::Simple from CPAN or checkout:

    git submodule init
	git submodule update

Feel free to fork and reuse!
