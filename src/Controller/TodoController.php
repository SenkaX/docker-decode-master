<?php

namespace App\Controller;

use App\Entity\Todo;
use App\Repository\TodoRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class TodoController extends AbstractController
{
    #[Route('/', name: 'app_todo', methods: ['GET', 'POST'])]
    public function index(Request $request, TodoRepository $todoRepository, EntityManagerInterface $entityManager): Response
    {
        if ($request->isMethod('POST')) {
            $titre = $request->request->get('titre');

            if (!empty($titre)) {
                $todo = new Todo();
                $todo->setTitre($titre);
                $todo->setDone(false);

                $entityManager->persist($todo);
                $entityManager->flush();

                $this->addFlash('success', 'Task added successfully!');
            }

            return $this->redirectToRoute('app_todo');
        }

        $todos = $todoRepository->findBy([], ['id' => 'ASC']);

        return $this->render('todo/index.html.twig', [
            'todos' => $todos,
        ]);
    }

    #[Route('/toggle/{id}', name: 'app_todo_toggle', methods: ['POST'])]
    public function toggle(Todo $todo, EntityManagerInterface $entityManager): Response
    {
        $todo->setDone(!$todo->isDone());

        $entityManager->flush();

        $message = $todo->isDone() ? 'Task completed! Great job.' : 'Task reopened.';
        $this->addFlash('success', $message);

        return $this->redirectToRoute('app_todo');
    }

    #[Route('/delete/{id}', name: 'app_todo_delete', methods: ['POST'])]
    public function delete(Todo $todo, EntityManagerInterface $entityManager): Response
    {
        $entityManager->remove($todo);

        $entityManager->flush();

        $this->addFlash('warning', 'Task deleted.');

        return $this->redirectToRoute('app_todo');
    }

    #[Route('/clear-completed', name: 'app_todo_clear_completed', methods: ['POST'])]
    public function clearCompleted(TodoRepository $todoRepository, EntityManagerInterface $entityManager): Response
    {
        $completedTodos = $todoRepository->findBy(['done' => true]);

        foreach ($completedTodos as $todo) {
            $entityManager->remove($todo);
        }

        $entityManager->flush();

        $this->addFlash('warning', 'All completed tasks have been cleared.');

        return $this->redirectToRoute('app_todo');
    }
}
