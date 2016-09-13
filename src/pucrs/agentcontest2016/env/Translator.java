package pucrs.agentcontest2016.env;

import jason.JasonException;
import jason.NoValueException;
import jason.asSyntax.ASSyntax;
import jason.asSyntax.ListTerm;
import jason.asSyntax.ListTermImpl;
import jason.asSyntax.Literal;
import jason.asSyntax.NumberTerm;
import jason.asSyntax.StringTerm;
import jason.asSyntax.Structure;
import jason.asSyntax.Term;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedList;

import eis.iilang.Action;
import eis.iilang.Function;
import eis.iilang.Identifier;
import eis.iilang.Numeral;
import eis.iilang.Parameter;
import eis.iilang.ParameterList;
import eis.iilang.Percept;

public class Translator {

	public static Literal perceptToLiteral(Percept per) throws JasonException {
		Literal l = ASSyntax.createLiteral(per.getName());
		for (Parameter par : per.getParameters())
			l.addTerm(parameterToTerm(per, par));
		return l;
	}

	public static Percept literalToPercept(jason.asSyntax.Literal l) throws NoValueException {
		Percept p = new Percept(l.getFunctor());
		for (Term t : l.getTerms())
			p.addParameter(termToParameter(t));
		return p;
	}

	public static Action literalToAction(Literal action) throws NoValueException {
		Parameter[] pars = new Parameter[action.getArity()];
		for (int i = 0; i < action.getArity(); i++)
			pars[i] = termToParameter(action.getTerm(i));
		return new Action(action.getFunctor(), pars);
	}

	public static Parameter termToParameter(Term t) throws NoValueException {
		if (t.isNumeric()) {
			return new Numeral(((NumberTerm) t).solve());
		} else if (t.isList()) {
			Collection<Parameter> terms = new ArrayList<Parameter>();
			for (Term listTerm : (ListTerm) t)
				terms.add(termToParameter(listTerm));
			return new ParameterList(terms);
		} else if (t.isString()) {
			return new Identifier(((StringTerm) t).getString());
		} else if (t.isLiteral()) {
			Literal l = (Literal) t;
			if (!l.hasTerm()) {
				return new Identifier(l.getFunctor());
			} else {
				Parameter[] terms = new Parameter[l.getArity()];
				for (int i = 0; i < l.getArity(); i++)
					terms[i] = termToParameter(l.getTerm(i));
				return new Function(l.getFunctor(), terms);
			}
		}
		return new Identifier(t.toString());
	}

	public static Term parameterToTerm(Percept per, Parameter par) throws JasonException {
		if (par instanceof Numeral) {
			return ASSyntax.createNumber(((Numeral) par).getValue().doubleValue());
		} else if (par instanceof Identifier) {
			try {
				Identifier i = (Identifier) par;
				String a = i.getValue();
				if (!Character.isUpperCase(a.charAt(0)))
					return ASSyntax.parseTerm(a);
			} catch (Exception e) {
			}
			return ASSyntax.createString(((Identifier) par).getValue());
		} else if (par instanceof ParameterList) {
			ListTerm list = new ListTermImpl();
			ListTerm tail = list;
			for (Parameter p : (ParameterList) par)
				tail = tail.append(parameterToTerm(per, p));
			return list;
		} else if (par instanceof Function) {
			return filter(per, par);
		}
		throw new JasonException("The type of parameter " + par + " is unknown!");
	}
	
	public static Structure filter(Percept per, Parameter par) throws JasonException{
		Function f = (Function) par;
		String name = f.getName();
		Structure l = ASSyntax.createStructure(name);
		if(name.equals("availableItem")){
			l = ASSyntax.createStructure("item");
		}
		for (Parameter p : f.getParameters())
			l.addTerm(parameterToTerm(per, p));
		if(per.getName().equals("shop") && name.equals("item")){
			l.addTerm(ASSyntax.createNumber(0));
			l.addTerm(ASSyntax.createNumber(0));
			l.addTerm(ASSyntax.createNumber(0));
		}
		return l;		
	}

	public static Action literalToAction(String actionlitstr) {
		Literal literal = Literal.parseLiteral(actionlitstr);
		LinkedList<Parameter> list = new LinkedList<Parameter>();
		String act = "";
		if(literal.getFunctor().equals("post_job")){
			ListTerm items = (ListTerm) literal.getTerms().remove(literal.getTerms().size()-1);
			for (Term term : literal.getTerms()) {
				Literal termlit = (Literal) term;
				act = act + termlit.getFunctor() + "=" + termlit.getTerm(0) + " ";
			}
			int index = 1;
			for(Term t: items.getAsList()){
				Literal item = (Literal) t;
				act = act + "item" + index + "=" + item.getTerm(0) + " amount" + index + "=" + item.getTerm(1) + " ";
				index++;
			}
		} else {
			for (Term term : literal.getTerms()) {
				Literal termlit = (Literal) term;
				act = act + termlit.getFunctor() + "=" + termlit.getTerm(0) + " ";
			}
		}
		list.add(new Identifier(act));
		return new Action(literal.getFunctor(), list);
	}
}
