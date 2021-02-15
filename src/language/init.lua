-- upstream: https://github.com/graphql/graphql-js/blob/00d4efea7f5b44088356798afff0317880605f4d/src/language/index.js

local printLocationImport = require(script.printLocation)
local parserImport = require(script.parser)
local visitorImport = require(script.visitor)
local astImport = require(script.ast)
local predicatesImport = require(script.predicates)

return {
	Source = require(script.source).Source,
	getLocation = require(script.location).getLocation,
	printLocation = printLocationImport.printLocation,
	printSourceLocation = printLocationImport.printSourceLocation,
	Kind = require(script.kinds).Kind,
	TokenKind = require(script.tokenKind).TokenKind,
	Lexer = require(script.lexer).Lexer,
	parse = parserImport.parse,
	parseValue = parserImport.parseValue,
	parseType = parserImport.parseType,
	print = require(script.printer).print,
	visit = visitorImport.visit,
	visitInParallel = visitorImport.visitInParallel,
	getVisitFn = visitorImport.getVisitFn,
	BREAK = visitorImport.BREAK,
	REMOVE = visitorImport.REMOVE, -- ROBLOX deviation - instead of null for removing node we use this token
	Location = astImport.Location,
	Token = astImport.Token,
	isDefinitionNode = predicatesImport.isDefinitionNode,
	isExecutableDefinitionNode = predicatesImport.isExecutableDefinitionNode,
	isSelectionNode = predicatesImport.isSelectionNode,
	isValueNode = predicatesImport.isValueNode,
	isTypeNode = predicatesImport.isTypeNode,
	isTypeSystemDefinitionNode = predicatesImport.isTypeSystemDefinitionNode,
	isTypeDefinitionNode = predicatesImport.isTypeDefinitionNode,
	isTypeSystemExtensionNode = predicatesImport.isTypeSystemExtensionNode,
	isTypeExtensionNode = predicatesImport.isTypeExtensionNode,
	DirectiveLocation = require(script.directiveLocation).DirectiveLocation,
}
