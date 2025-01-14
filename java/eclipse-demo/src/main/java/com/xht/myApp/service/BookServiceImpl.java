package com.xht.myApp.service;

import java.util.List;

import com.xht.myApp.domain.Book;
import com.xht.myApp.repository.BookNamedQueryRepositoryExample;
import com.xht.myApp.repository.BookOwnRepository;
import com.xht.myApp.repository.BookQueryRepositoryExample;
import com.xht.myApp.repository.BookRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


@Service
@Transactional
public class BookServiceImpl implements BookService {
	@Autowired
	private BookRepository bookRepository;
	@Autowired
	private BookOwnRepository bookOwnRepository;
	@Autowired
	private BookQueryRepositoryExample bookQueryRepository;
	@Autowired
	private BookNamedQueryRepositoryExample bookNamedQueryRepository;

	public List<Book> findAll() {
		return bookRepository.findAll();
	}
	
	public Page<Book> findAllByPage(PageRequest request) {
		request = new PageRequest(1, 2);
		return bookRepository.findAll(request);
	}

	public List<Book> findByName(String name) {
		return bookQueryRepository.findByName(name);
	}

	public List<Book> findByNameMatch(String name) {
		return bookQueryRepository.findByNameMatch(name);
	}

	public List<Book> findByNamedParam(String name, String author, long price) {
		return bookQueryRepository.findByNamedParam(name, author, price);
	}

	public List<Book> findByPriceRange(long price1, long price2) {
		return bookQueryRepository.findByPriceRange(price1, price2);
	}

	public List<Book> findByPrice(long price) {
		return bookNamedQueryRepository.findByPrice(price);
	}

	public List<Book> findByNameAndAuthor(String name, String author) {
		return bookOwnRepository.findByNameAndAuthor(name, author);
	}

	public void saveBook(Book book) {
		bookRepository.save(book);
	}

	public Book findOne(long id) {
		return bookRepository.findOne(id);
	}

	public void delete(long id) {
		bookRepository.delete(id);
	}
	
	@Transactional
	public void insert(Book book) {
		bookRepository.save(book);
	}
	
	@Transactional
	public void batchInsert(List<Book> books) {
		bookRepository.save(books);
	}
}
